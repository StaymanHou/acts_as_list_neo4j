# Neo4j Acts as list

This is a port of the classic +acts_as_list+ to Neo4j.

This *acts_as* extension provides the capabilities for sorting and reordering a number of objects in a list. 
If you do not specify custom position +column+ in the options, a key named +position+ will be used automatically.

## Installation

<code>gem install acts_as_list_neo4j</code>

## Usage

WARNING: This gem still requires refactoring. Currently, it only works OK for small workloads.

See the /specs folder specs that demontrate the API. Usage examples are located in the /examples folder.

To make a class Act as List, simply do:

<pre>
  include ActsAsList::Neo4j   
</pre>

And it will automatically set up a property and call acts_as_list with that property. By default the property name is :position.
You can change the defaut position_column name used: <code>ActsAsList::Neo4j.default_position_column = :pos</code>.
For this class variable to be effetive, it should be set before calling <code>include ActsAsList::Neo4j</code>.

## Example

<pre>
  class Item
    include Neo4j::ActiveNode
    include ActsAsList::Neo4j

    property :text
  end

  %w{'clean', 'wash', 'repair'}.each do |text|
    Item.new(text: text)
  end

  Item.first.move(:bottom)
  Item.last.move(:higher)
</pre>

## Overriding defaults

By default, when including ActsAsList::Neo4j, the property is set to :position and the acts_as_list column to :position. 
To change this:

<pre>
  include ActsAsList::Mongoid   
  
  property :pos, type: Integer
  acts_as_list column: :pos
</pre>

## move API
     
<pre>
item.move(:highest)          # moves to top of list.
item.move(:lowest)           # moves to bottom of list.
item.move(:top)              # moves to top of list.
item.move(:bottom)           # moves to bottom of list.
item.move(:up)               # moves one up (:higher and :up is the same) within the scope.
item.move(:down)             # moves one up (:lower and :down is the same) within the scope.
item.move(to: position)   # moves item to a specific position.
item.move(above: other)   # moves item above the other item.*
item.move(below: other)
</pre>

## Running the specs

<code>bundle exec rspec spec</code>
