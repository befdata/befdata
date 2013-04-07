class CounterCacheForDownloads < ActiveRecord::Migration
  def up
    rename_column :datasets, :downloads, :dataset_downloads_count
    Dataset.reset_column_information
    Dataset.find_each do |d|
      Dataset.reset_counters(d.id, :dataset_downloads)
    end
  end

  def down
    rename_column :datasets, :dataset_downloads_count, :downloads
  end
end
