class AddIndexToDatagroupTable < ActiveRecord::Migration
  def self.up
    # datagroup
    add_index :datagroups, [:id]
  end

  def self.down
    # datagroup
    remove_index :datagroups, [:id]
  end
end
