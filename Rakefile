$LOAD_PATH << 'lib'

require 'fileutils'
include FileUtils

namespace :tokyo do
  task :start do
    system 'ttserver -port 41414 data.tct 1>/dev/null &'
  end
  
  task :stop do
    system 'killall ttserver'
    rm_f 'data.tct'
  end
  
  task :run do
    puts "========== Running Tokyo Tyrant tests"
    Rake::Task['tokyo:start'].invoke
    require 'tokyo_test'
    Rake::Task['tokyo:stop'].invoke
  end
end

namespace :mongo do
  task :start do
    system 'mongod --dbpath /tmp 1>/dev/null &'
  end
  
  task :stop do
    system 'killall mongod'
    system '/bin/rm -rf /tmp/docdb*'
  end
  
  task :run do
    puts "========== Running MongoDB tests"
    Rake::Task['mongo:start'].invoke
    require 'mongo_test'
    Rake::Task['mongo:stop'].invoke
  end
end

task :couch do
end


task :test do
#  Rake::Task['tokyo:run'].invoke
#  puts `rake tokyo:run`
  puts `rake mongo:run`
#  `rake couch:run`
end

task :default => :test