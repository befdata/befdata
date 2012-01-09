class RemoveObsoleteFromDatagroupsAndDatacolumns < ActiveRecord::Migration
  def self.up
    remove_column :datacolumns, :missingcode
    remove_column :datagroups, :timelatency
    remove_column :datagroups, :timelatencyunit
  end

  def self.down
    add_column :datacolumns, :missingcode, :string
    add_column :datagroups, :timelatency, :float
    add_column :datagroups, :timelatencyunit, :string
  end
end
