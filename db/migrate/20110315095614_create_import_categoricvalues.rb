class CreateImportCategoricvalues < ActiveRecord::Migration
  def self.up
    create_table :import_categoricvalues do |t|
      t.integer  "datacolumn_id"
      t.string   "raw_data_value"
      t.integer  "categoricvalue_id"
      t.boolean  "approved"
      t.timestamps
    end
  end

  def self.down
    drop_table :import_categoricvalues
  end
end
