class CreateFilevalues < ActiveRecord::Migration
  def self.up
    create_table :filevalues do |t|
      t.string   "file_file_name"
      t.string   "file_content_type"
      t.integer  "file_file_size"
      t.datetime "file_updated_at"
      t.integer  "data_proposal_id"
      t.timestamps
    end
  end

  def self.down
    drop_table :filevalues
  end
end
