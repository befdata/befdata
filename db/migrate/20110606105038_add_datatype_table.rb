class AddDatatypeTable < ActiveRecord::Migration
  def self.up
    create_table :datatypes do |t|
      t.string   "name"
      t.string     "format"
    end
  end

  def self.down
    drop_table :datatypes
  end
end
