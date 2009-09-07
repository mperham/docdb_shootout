require 'benchmark'
require 'rubygems'
require 'rufus/tokyo/tyrant'
puts "Using rufus-tokyo #{Rufus::Tokyo::VERSION}"

def init_connection
  @db = Rufus::Tokyo::TyrantTable.new('localhost', 41414)
  @db.clear
  @db.set_index 'age', :decimal
end

def create_lots_of_documents(n=200_000)
  # Tokyo does not appear to have a bulk load operation
  # so we insert one at a time.
  count = 0
  while count < n
    @db["bob#{count}"] = { 
      'name' => 'Bob Jones',
      'email' => "bob#{rand(1000)}@example.com", 
      'age' => rand(100), 
      'birthdate' => rand(1_000_000_000), 
      'is_admin?' => rand(2),
    }
    count += 1
  end
end

def perform_queries
  results = @db.query do |q|
    q.add_condition 'age', :numge, '90'
    q.order_by 'birthdate'
    q.limit 1000
  end
  raise ArgumentError, "Unexpected query result: #{results.size}" if results.size != 1000
end

def bulk_delete_documents
  before_count = @db.size
  @db.query_delete do |q|
    q.add_condition 'age', :numge, '80'
  end
  after_count = @db.size
  raise ArgumentError, "Unexpected delete result: #{before_count} #{after_count}" if before_count == after_count
end

def done
  @db && @db.close
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