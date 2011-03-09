class RefactorPaperProposalToDataRequest < ActiveRecord::Migration
  def self.up
    rename_table :paper_proposals, :data_requests
    rename_column :filevalues, :paper_proposal_id, :data_requests_id
  end

  def self.down
    rename_table :data_requests, :paper_proposals
    rename_column :filevalues, :data_requests_id, :paper_proposal_id
  end
end
