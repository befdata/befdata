class MergeAccessRightsOfDatasets < ActiveRecord::Migration
  def up
    add_column :datasets, :access_code, :integer, :default => 0
    Dataset.reset_column_information
    Dataset.find_each do |dt|
      # use update_column instead of update_attribute
      dt.update_column(:access_code, calc_access_code(dt))
    end
    remove_columns :datasets, :free_for_public, :free_for_members, :free_within_projects
  end

  def down
    change_table(:datasets, :bulk => true) do |t|
      t.boolean  "free_for_members",   :default => false
      t.boolean  "free_for_public", :default => false
      t.boolean  "free_within_projects",   :default => false
    end
    Dataset.reset_column_information
    Dataset.record_timestamps = false
    Dataset.find_each do |dt|
      dt.update_attributes(:free_for_public => true, :free_for_members => true, :free_within_projects => true) if dt.access_code == 3
      dt.update_attributes(:free_for_members => true, :free_within_projects => true) if dt.access_code == 2
      dt.update_attributes(:free_within_projects => true) if dt.access_code == 1
    end
    Dataset.record_timestamps = true
    remove_column :datasets, :access_code
  end


private
  def calc_access_code(dataset)
    return 3 if dataset.read_attribute(:free_for_public)
    return 2 if dataset.read_attribute(:free_for_members)
    return 1 if dataset.read_attribute(:free_within_projects)
    return 0
  end
end
