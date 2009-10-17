require 'benchmark'
require 'rubygems'

gem 'jchris-couchrest'
require 'couchrest'
puts "Using jchris-couchrest #{CouchRest::VERSION}"

DB = CouchRest.database!("http://127.0.0.1:5984/docdb_shootout")
DB.recreate!

def init_connection
#  @db.create_index 'age'
end

def create_lots_of_documents(n=200_000, batch_size=1000)
  count = 0
  (n / batch_size).times do
    docs = []
    batch_size.times do
      docs << { 
        '_id' => "bob#{count}",
        'name' => 'Bob Jones',
        'email' => "bob#{rand(1000)}@example.com", 
        'age' => rand(100), 
        'birthdate' => Time.at(rand(1_000_000_000)), 
        'is_admin?' => rand(2) == 1,
      }      
    end
    DB.bulk_save(docs, false)
  end
end

class Person < CouchRest::ExtendedDocument
  use_database DB
  property :age, :type => Integer
  view_by :age
  
  def self.elderly(age)
    rs = Person.by_age(:startkey => age, :raw => true)
  end
end

def perform_queries
  p Person.elderly(99)
#  results = @db.find({ "age" => { '$gte' => 99 }}, :limit => 800, :sort => 'birthdate')
#  raise ArgumentError, "Unexpected query result: #{count}" if count < 800
end

def bulk_delete_documents
  @db.remove 'age' => { '$gte' => 80 }
end

def done
#  @db && @db.close
end

begin
  Benchmark.bm(10) do |x|
    x.report('init') { init_connection }
    x.report('create') { create_lots_of_documents }
    x.report('query') { perform_queries }
#    x.report('delete') { bulk_delete_documents }
  end
ensure
  done
end