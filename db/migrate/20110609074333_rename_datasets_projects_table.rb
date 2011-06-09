class RenameDatasetsProjectsTable < ActiveRecord::Migration
  def self.up
    rename_table('datasets_projects', 'dataset_projects')
  end

  def self.down
    rename_table('dataset_projects', 'datasets_projects')
  end
end
