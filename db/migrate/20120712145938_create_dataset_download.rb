class CreateDatasetDownload < ActiveRecord::Migration
  def self.up
    create_table :dataset_downloads do |t|
      t.integer  "user_id"
      t.integer  "dataset_id"
      t.timestamps
    end
  end

  def self.down
    drop_table :dataset_downloads
  end
end
