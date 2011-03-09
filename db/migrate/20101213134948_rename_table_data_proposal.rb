class RenameTableDataProposal < ActiveRecord::Migration
  def self.up
    rename_table :data_proposals, :paper_proposals
  end

  def self.down
    rename_table :paper_proposals, :data_proposals
  end
end
