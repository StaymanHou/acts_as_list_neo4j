require 'spec_helper'

ActsAsList::Neo4j.default_position_column = :pos
require 'item'

describe 'ActsAsList for Neo4j' do
  before :each do
    Neo4j::Session.current._query('MATCH (n) OPTIONAL MATCH (n)-[r]-() DELETE n,r')
    (1..4).each do |counter|
      Item.create(number: counter)
    end
  end

  after :each do
  end

  def get_positions
    Item.all.sort.map(&:number)
  end

  context '4 items (1,2,3,4)'  do
    describe '# initial configuration' do
      it 'should list items 1 to 4 in order' do
        positions = get_positions
        expect(positions).to eql [1, 2, 3, 4]
      end
    end

    describe '#reordering' do
      it 'should move item 2 to position 3' do
        Item.all[1].increment_position
        Item.all[2].decrement_position
        expect(get_positions).to eql [1, 3, 2, 4]
      end

      it 'should move item 2 to position 3' do
        Item.all.where(number: 2).first.move_lower
        expect(get_positions).to eql [1, 3, 2, 4]
      end

      it 'move :down should move item 2 to position 3' do
        Item.all.where(number: 2).first.move(:down)
        expect(get_positions).to eql [1, 3, 2, 4]
      end

      it 'move :lower should move item 2 to position 3' do
        Item.all.where(number: 2).first.move(:lower)
        expect(get_positions).to eql [1, 3, 2, 4]
      end

      it 'should move item 2 to position 1' do
        Item.all.where(number: 2).first.move_higher
        expect(get_positions).to eql [2, 1, 3, 4]
      end

      it 'move :up should move item 2 to position 1' do
        Item.all.where(number: 2).first.move(:up)
        expect(get_positions).to eql [2, 1, 3, 4]
      end

      it 'move :higher should move item 2 to position 1' do
        Item.all.where(number: 2).first.move(:higher)
        expect(get_positions).to eql [2, 1, 3, 4]
      end

      it 'should move item 1 to bottom' do
        Item.all.where(number: 1).first.move_to_bottom
        expect(get_positions).to eql [2, 3, 4, 1]
      end

      it 'move :lowest should move item 1 to bottom' do
        Item.all.where(number: 1).first.move(:lowest)
        expect(get_positions).to eql [2, 3, 4, 1]
      end

      it 'should move item 1 to top' do
        Item.all.where(number: 1).first.move_to_top
        expect(get_positions).to eql [1, 2, 3, 4]
      end

      it 'move :highest should move item 1 to top' do
        Item.all.where(number: 1).first.move(:highest)
        expect(get_positions).to eql [1, 2, 3, 4]
      end

      it 'move :unknown should cause argument error' do
        expect { Item.all.where(number: 1).first.move(:unknown) }.to raise_error
      end

      it 'should move item 2 to bottom' do
        Item.all.where(number: 2).first.move_to_bottom
        expect(get_positions).to eql [1, 3, 4, 2]
      end

      it 'should move item 4 to top' do
        Item.all.where(number: 4).first.move_to_top
        expect(get_positions).to eql [4, 1, 2, 3]
      end

      it 'should move item 3 to bottom' do
        Item.all.where(number: 3).first.move_to_bottom
        expect(get_positions).to eql [1, 2, 4, 3]
      end

      it 'items[2].move_to(4) should move item 2 to position 4' do
        Item.all.where(number: 2).first.move_to(4)
        expect(get_positions).to eql [1, 3, 4, 2]
      end

      it 'items[2].insert_at(3) should move item 2 to position 3' do
        Item.all.where(number: 2).first.insert_at(3)
        expect(get_positions).to eql [1, 3, 2, 4]
      end

      it 'items[2].move(:to => 3) should move item 2 to position 3' do
        Item.all.where(number: 2).first.move(to: 3)
        expect(get_positions).to eql [1, 3, 2, 4]
      end

      it 'items[1].move_below(item[2]) should move item 1 to position 2' do
        item2 = Item.all.where(number: 2).first
        Item.all.where(number: 1).first.move_below(item2)
        expect(get_positions).to eql [2, 1, 3, 4]
      end

      it 'items[3].move_below(item[1]) should move item 3 to position 2' do
        item1 = Item.all.where(number: 1).first
        Item.all.where(number: 3).first.move_below(item1)
        expect(get_positions).to eql [1, 3, 2, 4]
      end

      it 'items[3].move_above(item[2]) should move item 3 to position 2' do
        item2 = Item.all.where(number: 2).first
        Item.all.where(number: 3).first.move_above(item2)
        expect(get_positions).to eql [1, 3, 2, 4]
      end

      it 'items[1].move_above(item[3]) should move item 1 to position 2' do
        item3 = Item.all.where(number: 3).first
        Item.all.where(number: 1).first.move_above(item3)
        expect(get_positions).to eql [2, 1, 3, 4]
      end
    end

    describe 'relative position queries' do
      it 'should find item 2 to be lower item of item 1' do
        expected = Item.all.where(pos: 2).first
        expect(Item.all.where(pos: 1).first.lower_item).to eql expected
      end

      it 'should not find any item higher than nr 1' do
        expect(Item.all.where(pos: 1).first.higher_item).to be_nil
      end

      it 'should find item 3 to be higher item of item 4' do
        expected = Item.all.where(pos: 3).first
        expect(Item.all.where(pos: 4).first.higher_item).to eql expected
      end

      it 'should not find item lower than item 4' do
        expect(Item.all.where(pos: 4).first.lower_item).to be_nil
      end
    end
  end
end
