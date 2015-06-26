if ENV['COVERAGE']
  require 'simplecov'
  SimpleCov.start
end

require 'rspec'
require 'byebug'
require 'neo4j'
require 'acts_as_list_neo4j'

$LOAD_PATH.unshift "#{File.dirname(__FILE__)}/../model/"
ENV['NEO4J_ENV'] = 'test'
Neo4j::Session.open(:server_db, 'http://localhost:7474')
