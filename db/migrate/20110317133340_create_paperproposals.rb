class CreatePaperproposals < ActiveRecord::Migration
  def self.up
    create_table :paperproposals do |t|
      t.integer  "author_id"
      t.string   "envisaged_journal"
      t.string   "title"
      t.string   "rationale"
      t.integer  "corresponding_id"
      t.date     "envisaged_date"
      t.string   "state"
      t.date     "expiry_date"
      t.string   "board_state",       :default => "prep"
      t.integer  "senior_author_id"
      t.string   "external_data"
      t.boolean  "lock",              :default => false
      t.timestamps
    end
  end

  def self.down
    drop_table :paperproposals
  end
end
