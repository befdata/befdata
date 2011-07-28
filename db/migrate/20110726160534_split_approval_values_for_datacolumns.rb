class SplitApprovalValuesForDatacolumns < ActiveRecord::Migration
  def self.up
    rename_column :datacolumns, :approved, :datagroup_approved
    add_column :datacolumns, :datatype_approved, :boolean
  end

  def self.down
    remove_column :datacolumns, :datatype_approved
    rename_column :datacolumns, :datagroup_approved, :approved
  end
end
