require 'benchmark'
require 'rubygems'

gem 'mongodb-mongo'
require 'mongo'

def init_connection
  puts "Using mongodb-mongo"
  @db = Mongo::Connection.new('localhost').db('docdb_shootout').collection('test_data')
  @db.clear
  @db.create_index 'age'
end

def create_lots_of_documents(n=100_000)
  count = 0
  while count < n
    @db.insert({ 
      'name' => 'Bob Jones',
      'email' => "bob#{rand(1000)}@example.com", 
      'age' => rand(100), 
      'birthdate' => Time.at(rand(1_000_000_000)), 
      'is_admin?' => rand(2) == 1,
    })
    count += 1
  end
end

def perform_queries
  results = @db.find({ "age" => { :gte => 99 }}, :limit => 800, :sort => 'birthdate')
  results.next_object
  raise ArgumentError, "Unexpected query result: #{results.count}" if results.count < 800
  results.close
end

def bulk_delete_documents
  # Obama's death panels want to kill old records too.
  @db.remove 'age' => 80
end

def done
#  @db && @db.close
end

begin
  Benchmark.bm(10) do |x|
    x.report('init') { init_connection }
    x.report('create') { create_lots_of_documents }
    x.report('query') { perform_queries }
    x.report('delete') { bulk_delete_documents }
  end
ensure
  done
end