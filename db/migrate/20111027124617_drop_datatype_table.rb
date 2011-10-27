class DropDatatypeTable < ActiveRecord::Migration
  def self.up
    drop_table :datatypes
  end

  def self.down
  end
end
