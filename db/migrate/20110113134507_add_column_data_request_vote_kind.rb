class AddColumnDataRequestVoteKind < ActiveRecord::Migration
  def self.up
    add_column :data_request_votes, :project_board_vote, :boolean
  end

  def self.down
    remove_column :data_request_votes, :project_board_vote
  end
end
