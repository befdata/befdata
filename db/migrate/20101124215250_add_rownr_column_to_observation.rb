class AddRownrColumnToObservation < ActiveRecord::Migration
  def self.up
    add_column :observations, :rownr, :integer
  end 

  def self.down
    remove_column :observations, :rownr
  end
end
