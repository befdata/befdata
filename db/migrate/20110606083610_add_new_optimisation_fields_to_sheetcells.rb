class AddNewOptimisationFieldsToSheetcells < ActiveRecord::Migration
  def self.up
    remove_index :sheetcells, [:value_id, :value_type]
    add_column :sheetcells, :category_id, :integer
    add_column :sheetcells, :accepted_value, :string, :limit => 250
  end

  def self.down
    add_index :sheetcells, [:value_id, :value_type]
    remove_column :sheetcells, :category_id
    remove_column :sheetcells, :accepted_value
  end
end
