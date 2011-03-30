class CreateObservationSheetcells < ActiveRecord::Migration
  def self.up
    create_table :observation_sheetcells do |t|
      t.integer  "observation_id"
      t.integer  "sheetcell_id"
      t.text     "comment"
      t.timestamps
    end
  end

  def self.down
    drop_table :observation_sheetcells
  end
end
