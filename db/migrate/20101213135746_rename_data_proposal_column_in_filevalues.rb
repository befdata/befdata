class RenameDataProposalColumnInFilevalues < ActiveRecord::Migration
  def self.up
    rename_column :filevalues, :data_proposal_id, :paper_proposal_id
  end

  def self.down
    rename_column :filevalues, :paper_proposal_id, :data_proposal_id
  end
end
