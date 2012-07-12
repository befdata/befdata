class AddIndexDatasetDownloads < ActiveRecord::Migration
  def self.up
    add_index :dataset_downloads, [:user_id,:dataset_id]
  end

  def self.down
    remove_index :dataset_downloads, [:user_id,:dataset_id]
  end
end
