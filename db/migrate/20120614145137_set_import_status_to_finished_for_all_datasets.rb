class SetImportStatusToFinishedForAllDatasets < ActiveRecord::Migration
  def self.up
    # This is needed to initially generate all download files
    Dataset.all.each do |dataset|
      dataset.update_attribute(:import_status, 'finished')
      dataset.enqueue_to_generate_download
    end
  end

  def self.down
  end
end
