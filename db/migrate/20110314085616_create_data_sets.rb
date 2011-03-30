class CreateDataSets < ActiveRecord::Migration
  def self.up
    create_table :datasets do |t|
      t.string   "title"
      t.text     "abstract"
      t.text     "usagerights"
      t.text     "spatialextent"
      t.text     "temporalextent"
      t.text     "taxonomicextent"
      t.text     "design"
      t.text     "circumstances"
      t.datetime "submission_at"
      t.string   "filename"
      t.text     "comment"
      t.text     "dataanalysis"
      t.boolean  "finished"
      t.integer  "downloads",             :default => 0
      t.datetime "datemin"
      t.datetime "datemax"
      t.text     "published"
      t.boolean  "visible_for_public",    :default => true
      t.integer  "upload_spreadsheet_id"
      t.timestamps
    end
  end

  def self.down
    drop_table :data_sets
  end
end
