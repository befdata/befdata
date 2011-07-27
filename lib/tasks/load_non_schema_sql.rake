namespace :db do
  desc 'Add plpgsql functions to your database which are not included in our schema.rb
        Set RAILS_ENV to override environment'
  task :load_non_schema_sql => :environment do
    ActiveRecord::Base.establish_connection(RAILS_ENV.to_sym)
    sql = File.open("db/non_schema_sql.sql").read
    ActiveRecord::Base.connection.execute(sql)
  end
end