class SetImportStatusToUnknownForAllDatasets < ActiveRecord::Migration
  def self.up
    Dataset.all.each do |dataset|
      dataset.import_status = 'unknown'
    end
  end

  def self.down
  end
end
