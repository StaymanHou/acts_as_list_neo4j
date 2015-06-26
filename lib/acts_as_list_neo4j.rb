require 'neo4j'
require 'neo4j/acts_as_list'

class Module
  def act_as_list
    send :include, ActsAsList::Neo4j
  end
end
