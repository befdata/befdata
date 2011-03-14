class CreateSheetcells < ActiveRecord::Migration
  def self.up
    create_table :sheetcells do |t|
      t.integer  "data_column_id"
      t.integer  "value_id"
      t.string   "value_type"
      t.integer  "rownr"
      t.text     "comment"
      t.integer  "observation_id"
      t.string   "import_value"
      t.timestamps
    end
  end

  def self.down
    drop_table :sheetcells
  end
end
