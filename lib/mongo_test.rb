require 'benchmark'
require 'rubygems'

=begin
 gem install gemcutter
 gem tumble
 gem install mongo
 gem install mongo_ext
=end

gem 'mongo'
require 'mongo'
puts "Using mongo #{Mongo::VERSION}"

class Mongo::Collection
  def size
    find({}, :fields => { '_id' => 1 }).count
  end
end

# http://api.mongodb.org/ruby/
def init_connection
  @db = Mongo::Connection.new('localhost').db('docdb_shootout').collection('test_data')
  @db.clear
  @db.create_index 'age'
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
      count += 1
    end
    @db.insert(docs)
  end
end

def perform_queries
  count = 0
  @db.find({ "age" => { '$gte' => 90 }}, :limit => 1000, :sort => [['birthdate']]) do |cursor|
    # Mongo does not perform the query until the cursor actually needs the data so we have
    # to eager load the results.
    cursor.each do |row|
      count += 1
    end
  end
  raise ArgumentError, "Unexpected query result: #{results.count}" if count < 1000
end

def bulk_delete_documents
  before_count = @db.size
  @db.remove 'age' => { '$gte' => 80 }
  after_count = @db.size
  raise ArgumentError, "Unexpected delete result: #{before_count} #{after_count}" if before_count == after_count
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