class ChangePaperproposalEnvisagedJournalToText < ActiveRecord::Migration
  def up
    change_column :paperproposals, :envisaged_journal, :text
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
