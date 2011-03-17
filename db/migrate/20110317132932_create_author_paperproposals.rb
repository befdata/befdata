class CreateAuthorPaperproposals < ActiveRecord::Migration
  def self.up
    create_table :author_paperproposals do |t|
      t.integer  "paperproposal_id"
      t.integer  "user_id"
      t.string   "kind"
      t.timestamps
    end
  end

  def self.down
    drop_table :author_paperproposals
  end
end
