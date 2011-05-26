class RenameFilevalueToDatafile < ActiveRecord::Migration
  def self.up
    remove_index :filevalues, [:paperproposal_id]
    rename_table :filevalues, :datafiles
    add_index :datafiles, [:paperproposal_id]
  end

  def self.down
    remove_index :datafiles, [:paperproposal_id]
    rename_table :datafiles, :filevalues
    add_index :filevalues, [:paperproposal_id]
  end
end


    