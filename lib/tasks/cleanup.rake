namespace :cleanup do
  desc 'cleanup categories without associated sheetcells'
  task :categories => :environment do
    Category.delete_orphan_categories
  end

  desc 'cleanup datagroups without associated datacolumns'
  task :datagroups => :environment do
    Datagroup.delete_orphan_datagroups
  end

  desc "invoke all cleanup tasks"
  task :all => :environment do
    Rake::Task["cleanup:categories"].invoke
    Rake::Task["cleanup:datagroups"].invoke
  end
end