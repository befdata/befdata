class CreatePaperproposalVotes < ActiveRecord::Migration
  def self.up
    create_table :paperproposal_votes do |t|
      t.integer  "paperproposal_id"
      t.integer  "user_id"
      t.string   "comment"
      t.string   "vote",               :default => "none"
      t.boolean  "project_board_vote"

      t.timestamps
    end
  end

  def self.down
    drop_table :paperproposal_votes
  end
end
