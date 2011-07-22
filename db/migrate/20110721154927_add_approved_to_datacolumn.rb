class AddApprovedToDatacolumn < ActiveRecord::Migration
  def self.up
    add_column :datacolumns, :approved, :boolean
  end

  def self.down
    remove_column :datacolumns, :approved
  end
end
