class AddColumnDataProposalIdToFileValues < ActiveRecord::Migration
  def self.up
    add_column :filevalues, :data_proposal_id, :integer
  end

  def self.down
    remove_column :filevalues, :data_proposal_id
  end
end
