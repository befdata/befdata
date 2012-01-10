class RenameDatasetProjectJoinTableAndRemovePrimaryKeyAndComment < ActiveRecord::Migration
  def self.up
    rename_table :dataset_projects, :datasets_projects
    remove_column :datasets_projects,  :id
    remove_column :datasets_projects, :comment
  end

  def self.down
    rename_table :datasets_projects, :dataset_projects
  end
end
