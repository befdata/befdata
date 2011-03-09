class AddImportValueToMasurements < ActiveRecord::Migration
  def self.up
    add_column :measurements, :import_value, :string
  end

  def self.down
    remove_column :measurements, :import_value
  end
end
