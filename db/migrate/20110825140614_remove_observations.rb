class RemoveObservations < ActiveRecord::Migration
  def self.up
    drop_table :observations
    drop_table :observation_sheetcells
    remove_column :sheetcells, :observation_id
    #The indexes seem to already have been removed by drop_table ... check manually
    #remove_index "sheetcells", ["observation_id"]
    #remove_index "observation_sheetcells", ["observation_id", "sheetcell_id"]
  end

  def self.down
    create_table "observations" do |t|
      t.text "comment"
      t.integer "rownr"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "observation_sheetcells" do |t|
      t.integer "observation_id"
      t.integer "sheetcell_id"
      t.text "comment"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_column :sheetcells, :observation_id, :integer
    add_index "observation_sheetcells", ["observation_id", "sheetcell_id"],
              :name => "index_observation_sheetcells_on_observation_id_and_sheetcell_id"
    add_index "sheetcells", ["observation_id"], :name => "index_sheetcells_on_observation_id"

    
  end
end
