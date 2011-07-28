class AddFinishedValueToDatacolumns < ActiveRecord::Migration
  def self.up
    add_column :datacolumns, :finished, :boolean
  end

  def self.down
    remove_column :datacolumns, :finished
  end
end
