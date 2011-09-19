class RemovedDatasetFinishedAsUnused < ActiveRecord::Migration
  def self.up
    remove_column :datasets, :finished
  end

  def self.down
    add_column :datasets, :finished, :boolean
  end
end
