require 'benchmark'
require 'rubygems'

gem 'jchris-couchrest'
require 'couchrest'
puts "Using jchris-couchrest #{CouchRest::VERSION}"

def init_connection
  @db = CouchRest.database!("http://127.0.0.1:5984/docdb_shootout")
  @db.recreate!
#  @db.create_index 'age'
end

def create_lots_of_documents(n=20_000, batch_size=1000)
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
    @db.bulk_save(docs, false)
  end
end

class Person < CouchRest::ExtendedDocument
  view_by :age
  
  def self.elderly(age, db)
    rs = Person.by_age(:startkey => age, :database => db, :raw => true)
  end
end

def perform_queries
  count = Person.elderly(99, @db)['total_rows']
#  results = @db.find({ "age" => { '$gte' => 99 }}, :limit => 800, :sort => 'birthdate')
  raise ArgumentError, "Unexpected query result: #{count}" if count < 800
end

def bulk_delete_documents
  # Obama's death panels want to kill old records too.
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