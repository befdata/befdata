class AddImportStatusToDataset < ActiveRecord::Migration
  def self.up
    add_column :datasets, :import_status, :string
  end

  def self.down
    remove_column :datasets, :import_status
  end
end
