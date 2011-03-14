class CreateDatacolumns < ActiveRecord::Migration
  def self.up
    create_table :datacolumns do |t|
      t.integer  "datagroup_id"
      t.integer  "dataset_id"
      t.string   "columnheader"
      t.integer  "columnnr"
      t.text     "definition"
      t.string   "unit"
      t.string   "missingcode"
      t.text     "comment"
      t.string   "import_data_type"
      t.string   "category_longshort"
      t.timestamps
    end
  end

  def self.down
    drop_table :datacolumns
  end
end
