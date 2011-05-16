class ChangePaperproposalRationaleTypeToText < ActiveRecord::Migration
  def self.up
     change_column :paperproposals, :rationale, :text
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
