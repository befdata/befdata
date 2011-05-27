class AddProvenanceModifierToDatasets < ActiveRecord::Migration
  def self.up
    add_column :datasets, :free_for_members, :boolean, :default => false
    add_column :datasets, :free_for_public, :boolean, :default => false
    add_column :datasets, :free_within_projects, :boolean, :default => false
    add_column :datasets, :student_file, :boolean, :default => false
  end

  def self.down
    remove_column :datasets, :free_for_members
    remove_column :datasets, :free_for_public
    remove_column :datasets, :free_within_projects
    remove_column :datasets, :student_file
  end
end
