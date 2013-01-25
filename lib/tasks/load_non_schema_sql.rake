namespace :db do
  desc 'Add plpgsql functions to your database which are not included in our schema.rb
        Set RAILS_ENV to override environment'
  task :load_non_schema_sql => :environment do
    ActiveRecord::Base.establish_connection(Rails.env.to_sym)
    sql_filename = "db/non_schema_sql.sql"
    sql = File.open(sql_filename).read
    ActiveRecord::Base.connection.execute(sql)
  end
end

#This adds loading non_schema_sql if the usual schema load task is executed
namespace :db do
  namespace :schema do
    task :load => :environment do
      Rake::Task["db:load_non_schema_sql"].invoke
    end
  end
end