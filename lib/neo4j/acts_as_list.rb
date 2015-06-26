require 'neo4j'

module ActsAsList
  module Neo4j
    class << self
      attr_accessor :default_position_column
    end

    def self.included(klass)
      klass.extend InitializerMethods
      key = default_position_column || :position
      klass.property key, type: Integer
      klass.acts_as_list column: key.to_s
    end

    module InitializerMethods
      def acts_as_list(options = {})
        configuration = { column: 'position' }
        configuration.update(options) if options.is_a?(Hash)

        if configuration[:scope]
          configuration[:scope] = configuration[:scope].to_sym
          configuration[:scope] = "#{configuration[:scope]}_id".intern if configuration[:scope].to_s !~ /_id$/
        end

        define_method :position_column do
          configuration[:column].to_s
        end

        if !configuration[:scope]
          define_method :scope_condition do
            { "i.#{position_key} <>" => nil }
          end
        elsif configuration[:scope].is_a?(Symbol)
          define_method :scope_condition do
            { configuration[:scope] => self[configuration[:scope]] }
          end
        else
          fail ArgumentError, 'acts_as_list must either take a valid :scope option or be in an embedded document and use the parent document as scope'
        end

        include InstanceMethods
        include Fields
        include Triggers
        extend Fields
        extend ClassMethods

        before_create :init_list_item
      end
    end

    module ClassMethods
      def in_scope
        where(scope_condition)
      end

      def move_commands(symbol)
        case symbol
        when :symbol
          [:highest, :top, :lowest, :bottom, :up, :higher, :down, :lower]
        when :hash
          [:to, :above, :below]
        else
          fail ArgumentError, "no move_commands defined for: #{symbol}"
        end
      end
    end

    module InstanceMethods
      def move command
        if command.is_a? Symbol
          case command
          when :highest, :top
            move_to_top
          when :lowest, :bottom
            move_to_bottom
          when :up, :higher
            move_higher
          when :down, :lower
            move_lower
          else
            fail ArgumentError, "unknown move command '#{command}', try one of #{self.class.move_commands_available}"
          end
        elsif command.is_a? Hash
          other = command.values.first
          cmd = command.keys.first
          case cmd
          when :to
            move_to(other)
          when :above
            move_above(other)
          when :below
            move_below(other)
          else
            fail ArgumentError, "Hash command #{cmd.inspect} not valid, must be one of"
          end
        else
          fail ArgumentError, "move command takes either a Symbol or Hash as an argument, not a #{command.class}"
        end
      end

      def order_by_position(conditions, extras = [])
        sub_collection = self_class_all_or_in_collection.where(stringify_conditions(conditions))
        sub_collection = sub_collection.order_by("i.#{position_key}").pluck(:i)

        sub_collection = sub_collection.order_by(extras) unless extras.empty?

        sub_collection
      end

      # conditions, { position_column => 1 }
      def do_decrement(conditions, _options)
        self_class_all_or_in_collection.where(stringify_conditions(conditions)).pluck(:i).each do |item|
          item.adjust_position(-1)
        end
      end

      def do_increment(conditions, _options)
        self_class_all_or_in_collection.where(stringify_conditions(conditions)).pluck(:i).each do |item|
          item.adjust_position(-1)
        end
      end

      def less_than_me
        { "i.#{position_key} <" => my_position.to_i }
      end

      def greater_than_me
        { "i.#{position_key} >" => my_position.to_i }
      end

      def insert_at(position = 1)
        insert_in_list_at(position)
      end

      def move_to(position = 1)
        insert_in_list_at(position)
      end

      def move_below(object)
        return if self == object
        if object.my_position > my_position
          move_to(object.my_position)
        else
          move_to(object.my_position + 1)
        end
      end

      def move_above(object)
        return if self == object
        if object.my_position > my_position
          move_to(object.my_position - 1)
        else
          move_to(object.my_position)
        end
      end

      # Insert the item at the given position (defaults to the top position of 1).
      def insert_in_list_at(position = 1)
        insert_at_position(position)
      end

      # Swap positions with the next lower item, if one exists.
      def move_lower
        low_item = lower_item
        return unless low_item

        low_item.decrement_position
        increment_position
      end

      # Swap positions with the next higher item, if one exists.
      def move_higher
        high_item = higher_item
        return unless high_item

        high_item.increment_position
        decrement_position
      end

      # Move to the bottom of the list. If the item is already in the list, the items below it have their
      # position adjusted accordingly.
      def move_to_bottom
        return unless in_list?

        decrement_positions_on_lower_items
        assume_bottom_position
      end

      # Move to the top of the list. If the item is already in the list, the items above it have their
      # position adjusted accordingly.
      def move_to_top
        return unless in_list?

        increment_positions_on_higher_items
        assume_top_position
      end

      # Removes the item from the list.
      def remove_from_list
        return unless in_list?
        decrement_positions_on_lower_items
        set_my_position nil
      end

      # Increase the position of this item without adjusting the rest of the list.
      def increment_position
        return unless in_list?
        # self_class_all_or_in_collection.where(:pos => my_position).
        adjust_position!(1)
      end

      # Decrease the position of this item without adjusting the rest of the list.
      def decrement_position
        return unless in_list?

        # self_class_all_or_in_collection.where(:pos => my_position).
        adjust_position!(-1)
      end

      # Return +true+ if this object is the first in the list.
      def first?
        return false unless in_list?
        my_position == 1
      end

      # Return +true+ if this object is the last in the list.
      def last?
        return false unless in_list?
        bottom_pos = bottom_position_in_list
        my_position == bottom_pos
      end

      # Return the next higher item in the list.
      def higher_item
        return nil unless in_list?
        conditions = scope_condition.merge!(less_than_me)
        order_by_position(conditions).last
      end

      # Return the next lower item in the list.
      def lower_item
        return nil unless in_list?

        conditions = scope_condition.merge!(greater_than_me)
        order_by_position(conditions).first
      end

      # Test if this record is in a list
      def in_list?
        !my_position.nil?
      end

      # sorts all items in the list
      # if two items have same position, the one created more recently goes first
      def sort
        conditions = scope_condition
        list_items = order_by_position(conditions, :created_at.desc).to_a

        list_items.each_with_index do |list_item, index|
          list_item.set_my_position index + 1
        end
      end

      private

      def self_class_all_or_in_collection
        return in_collection.query_as(:i) if self.respond_to?(:in_collection)
        self.class.all.query_as(:i)
      end

      def add_to_list_bottom
        bottom_pos = bottom_position_in_list.to_i
        set_my_position(bottom_pos + 1)
      end

      # Overwrite this method to define the scope of the list changes
      def scope_condition
        {}
      end

      # Returns the bottom position number in the list.
      #   bottom_position_in_list    # => 2
      def bottom_position_in_list(_except = nil)
        item = bottom_item # (except)
        item ? item.my_position : 0
      end

      # Returns the bottom item
      def bottom_item(except = nil)
        conditions = scope_condition
        if except
          conditions.merge!("i.#{position_key} <>" => except.my_position)
        end

        order_by_position(conditions).last
      end

      # Forces item to assume the bottom position in the list.
      def assume_bottom_position
        pos = bottom_position_in_list(self).to_i + 1
        set_my_position(pos)
      end

      # Forces item to assume the top position in the list.
      def assume_top_position
        set_my_position(1)
      end

      # This has the effect of moving all the higher items up one.
      def decrement_positions_on_higher_items(position)
        conditions = scope_condition
        conditions.merge!("i.#{position_key} <" => position)

        decrease_all! self_class_all_or_in_collection.where(stringify_conditions(conditions))
      end

      # This has the effect of moving all the lower items up one.
      def decrement_positions_on_lower_items(max_pos = nil)
        return unless in_list?
        conditions = scope_condition
        conditions.merge!(greater_than_me)
        conditions.merge!("i.#{position_key} <" => max_pos) if max_pos

        decrease_all! self_class_all_or_in_collection.where(stringify_conditions(conditions))
      end

      # This has the effect of moving all the higher items down one.
      def increment_positions_on_higher_items(min_pos = nil)
        return unless in_list?
        conditions = scope_condition
        conditions.merge!(less_than_me)
        conditions.merge!("i.#{position_key} >" => min_pos) if min_pos

        increase_all! self_class_all_or_in_collection.where(stringify_conditions(conditions))
      end

      def adjust_all!(collection, number)
        collection.pluck(:i).each do |item|
          item.adjust_position! number
        end
      end

      def increase_all!(collection)
        adjust_all! collection, 1
      end

      def decrease_all!(collection)
        adjust_all! collection, -1
      end

      # This has the effect of moving all the lower items down one.
      def increment_positions_on_lower_items(position)
        conditions = scope_condition
        conditions.merge!("i.#{position_key} >=" => position)

        increase_all! self_class_all_or_in_collection.where(stringify_conditions(conditions))
      end

      # Increments position (<tt>position_column</tt>) of all items in the list.
      def increment_positions_on_all_items
        conditions = scope_condition
        increase_all! self_class_all_or_in_collection.where(stringify_conditions(conditions))
      end

      alias_method :add_to_list_top, :increment_positions_on_all_items

      def insert_at_position(position)
        position = [position, 1].max
        remove_from_list
        increment_positions_on_lower_items(position)
        set_my_position(position)
      end

      def stringify_conditions(conditions)
        return nil if conditions.empty?
        conditions.reject { |_key, value| value.nil? }.map { |key, value| "#{key} #{value}" }.join(' and ')
      end
    end

    module Triggers
      def after_parentize
        # should register on root element to be called when root is saved first time!?
      end

      def init_list_item
        add_to_list_bottom unless in_list?
      end
    end

    module Fields
      def my_position
        send position_column
      end

      def set_my_position(new_position)
        return if new_position == my_position
        if id
          update_attributes! position_column => new_position
        else
          send "#{position_column}=", new_position
        end
      end

      def ==(other)
        return true if other.equal?(self)
        return true if other.instance_of?(self.class) && other.respond_to?('id') && other.id == id
        false
      end

      # Overwrites default comparer to return comparison index value based on defined position
      def <=>(other)
        my_position <=> other.my_position
      end

      def position_key
        position_column.to_sym
      end

      def adjust_position!(number)
        adjust_position(number)
        save!
      end

      def adjust_position(number)
        set_my_position(my_position + number)
      end
    end
  end
end

class Array
  def init_list!
    each(&:init_list_item!)
  end
end
