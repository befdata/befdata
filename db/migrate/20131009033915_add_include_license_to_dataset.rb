class AddIncludeLicenseToDataset < ActiveRecord::Migration
  def change
    add_column :datasets, :include_license, :boolean, :default => false
  end
end
