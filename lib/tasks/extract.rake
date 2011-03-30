# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

#require(File.join(File.dirname(__FILE__), 'config', 'boot'))

require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

#require 'tasks/rails'
require 'pathname'

namespace :mine do
  def project_models
    Dir['app/models/*'].inject([]) do |models,file|
      file = Pathname.new(file).basename.to_s.gsub(/.rb$/, '')
      model = file.camelize.constantize
      models << file.camelize if model < ActiveRecord::Base and !model.abstract_class?
      models
    end
  end

  desc <<-DESC.gsub(/[ ]+\|/m, "").strip
       |Count the number of models to be processed for fixtures  
       DESC
  task :count_models => :environment do
    models = project_models
    puts "models to be processed is #{models.size}"
  end

  namespace :fixtures do
    def fixture_name_on_collision(fixture_name, model)
      if FileTest.exist?("#{RAILS_ROOT}/test/fixtures/#{fixture_name}.yml")
        remedy = ""
        old_fixture = [fixture_name.clone]
        fixture_name = model.to_s
        remedy = "using model name"
        puts "using model name | fixture_name: #{fixture_name}"
        
        if FileTest.exist?("#{RAILS_ROOT}/test/fixtures/#{fixture_name}.yml")
          old_fixture << fixture_name.clone 
          model_name = model.table_name.split('.')
          fixture_name = "#{model_name[0].split('_').first}#{model_name.last}"
          remedy = "using full table name"
          puts "using full table name | fixture_name: #{fixture_name}"
          
          if FileTest.exist?("#{RAILS_ROOT}/test/fixtures/#{fixture_name}.yml")
            old_fixture << fixture_name.clone
            remedy = "using full table name with random prefix"
            fixture_name = "#{Rand(rand*10_000).to_i}_#{fixture_name}"
            puts "using full table name with random prefix | fixture_name: #{fixture_name}"
          end
        end
        puts "the fixtures #{old_fixture.inspect} already exists so, #{remedy}, for model #{model} to #{fixture_name}"
      end
      fixture_name
    end
    
    desc <<-DESC.gsub(/[ ]+\|/m, "").strip
       |Create YAML test fixtures for a specific model with the name if specified
       |needs two args: :model, :fixture_name
       DESC
    task :extract_specific, [:model, :fixture_name] => :environment do |t, args|
      model = args[:model]
      fixture_name = args[:fixture_name]

      # models which do not require fixtures do to any reason.
      # eg. it is a duplicate of another model, only difference is that the db connection
      # is different ie. it is a slave database on another machine.
      if ["ReadonlyAccountTrail"].include?(model)
        puts "Skipped #{model} as configured"
        next #rake tasks are blocks not methods so we use next and not return, which would not work 
      end
      
      # HACK: removes the class info so that type-info is omitted
      # yaml guesses for the default types but did not find (easily) a configuration
      YAML.instance_eval { @tagged_classes = {} }

      model = model.constantize
      # does not consider if a table by the same name exists
      # in two different database.
      # eg table _name is either of DB1.FooBar and DB2.FooBar
      unless fixture_name
        #puts "fixture_name not specified so taking the table name"
        fixture_name = model.table_name.split('.').last
      end
      fixture_name = fixture_name_on_collision(fixture_name, model)

      i = "000"
      File.open("#{RAILS_ROOT}/test/fixtures/#{fixture_name}.yml", 'w') do |file|
        puts "Generating #{model} as #{fixture_name}"
        
        data = model.find(:all, :order => ["id desc"]) rescue model.all 
        file.write data.inject({}) { |hash, record|
          hash["#{fixture_name}_#{i.succ!}"] = record.attributes
          hash
        }.to_yaml
      end
    end #task fixtures:extract_specific
    
    desc <<-DESC.gsub(/[ ]+\|/m, "").strip
       |Create YAML test fixtures from data in an existing database.    
       |Requires a list of models which are dumped to yaml using the
       |actual connection configured for the model
       |either provide MODELS as a csv to models or ALL_MODELS=true for all the models
       DESC
    task :extract => :environment do
      unless ENV['MODELS'] || ENV['ALL_MODELS'] 
        abort('either provide MODELS as a csv to models or ALL_MODELS=true for all the models')
      end

      if ENV['ALL_MODELS']
        models = project_models
        puts "models to be processed is #{models.size}"
        ENV['MODELS'] = models.join(',')
      end
      
      ENV['MODELS'].split(',').each do |model|
        Rake::Task["mine:fixtures:extract_specific"].invoke(model)
        Rake::Task["mine:fixtures:extract_specific"].reenable
      end
    end #task fixtures:extract

    # http://snippets.dzone.com/posts/show/2525
    desc <<-DESC.gsub(/[ ]+\|/m, "").strip
       |Create YAML test fixtures from a table which does not have a model    
       |Defaults to development database.  Set RAILS_ENV to override.
       |provide MODEL as the model connection to use or base is the default 
       DESC
    task :dump => :environment do 
      sql  = "SELECT * FROM %s"
      skip_tables = ["schema_info"]

      conn = ActiveRecord::Base
      if ENV['MODEL']
        conn = ENV['MODEL'].camelize.constantize
      end
      conn.establish_connection

      # does not check if we have some fixtures in some other db connection
      (conn.connection.tables - skip_tables).each do |table_name|
        i = "000"
        model_name = table_name.camelize
        File.open("#{RAILS_ROOT}/test/fixtures/#{model_name}.yml", 'w') do |file|
          puts "Generating #{model_name} from #{conn}"
          data = conn.connection.select_all(sql % table_name)
          file.write data.inject({}) { |hash, record|
            hash["#{model_name}_#{i.succ!}"] = record
            hash
          }.to_yaml
        end
      end
    end #task fixtures:dump

    desc <<-DESC.gsub(/[ ]+\|/m, "").strip
       |Create YAML test fixtures from a table which does not have a model     
       |Defaults to development database.  Set RAILS_ENV to override.
       |needs two args: :table_name (required), :model_conn (defaults to RAILS_ENV default database) 
       DESC
    task :dump_specific => :environment do |t,args|
      table_name = args[:table_name]
      model_conn = args[:model_conn]
      
      sql  = "SELECT * FROM %s"
      skip_tables = ["schema_info"]
      if model_conn
        model_conn = model_conn.camelize.constantize
        puts "using the #{model_conn} connection"
      else
        model_conn = ActiveRecord::Base
        puts "using the base connection"
      end

      # does not check if we have some fixtures in some other db connection
      i = "000"
      model_name = table_name.camelize
      File.open("#{RAILS_ROOT}/test/fixtures/#{model_name}.yml", 'w') do |file|
        puts "Generating #{model_name} connected by #{model_conn}"
        data = model_conn.connection.select_all(sql % table_name)
        file.write data.inject({}) { |hash, record|
          hash["#{model_name}_#{i.succ!}"] = record
          hash
        }.to_yaml
      end
    end #task fixtures:dump_specific
  end #namespace :fixtures
end #namespace :mine