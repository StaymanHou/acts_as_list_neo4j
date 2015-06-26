class Item
  include Neo4j::ActiveNode
  include ActsAsList::Neo4j

  property :number, type: Integer
end
