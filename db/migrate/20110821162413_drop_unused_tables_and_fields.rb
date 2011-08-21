class DropUnusedTablesAndFields < ActiveRecord::Migration
  def self.up
    remove_column :sheetcells, :value_id
    remove_column :sheetcells, :value_type
    remove_column :sheetcells, :rownr

    drop_table :datetimevalues
    drop_table :textvalues
    drop_table :numericvalues
  end

  def self.down
  end
end
