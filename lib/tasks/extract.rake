# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require(File.join(File.dirname(__FILE__), 'config', 'boot'))

require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

require 'tasks/rails'

namespace :mine do
  # http://snippets.dzone.com/posts/show/2525
  desc <<-DESC.gsub(/[ ]+\|/m, "").strip
       |Create YAML test fixtures from data in an existing database.
       |Requires a list of models which are dumped to yaml using the
       |actual connection configured for the model
       DESC
  task :extract_fixtures => :environment do
    return 1 unless ENV['MODELS']

    skip_tables = ["schema_info"]
    ActiveRecord::Base.establish_connection

    ENV['MODELS'].split(',').each do |model|
      model = model.constantize
      # does not consider if a table by the same name exists
      # in two different database.
      # eg table _name is either of DB1.FooBar and DB2.FooBar
      table_name = model.table_name.split('.').last

      i = "000"
      File.open("#{Rails.root}/test/fixtures/#{table_name}.yml", 'w') do |file|
        puts "Generating #{table_name}"
        data = model.all
        file.write data.inject({}) { |hash, record|
          hash["#{table_name}_#{i.succ!}"] = record
          hash
        }.to_yaml
      end
    end
  end #task :extract_fixtures

  desc <<-DESC.gsub(/[ ]+\|/m, "").strip
       |Create YAML test fixtures from data in an existing database.
       |Defaults to development database.  Set RAILS_ENV to override.
       DESC
  task :dump_fixtures => :environment do
    sql  = "SELECT * FROM %s"
    skip_tables = ["schema_info"]
    ActiveRecord::Base.establish_connection
    # does not check if we have some fixtures in some other db connection
    (ActiveRecord::Base.connection.tables - skip_tables).each do |table_name|
      i = "000"
      File.open("#{Rails.root}/test/fixtures/#{table_name}.yml", 'w') do |file|
        puts "Generating #{table_name}"
        data = ActiveRecord::Base.connection.select_all(sql % table_name)
        file.write data.inject({}) { |hash, record|
          hash["#{table_name}_#{i.succ!}"] = record
          hash
        }.to_yaml
      end
    end
  end #task :extract_fixtures
end #namespace :mine