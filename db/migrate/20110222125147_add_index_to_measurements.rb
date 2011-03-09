class AddIndexToMeasurements < ActiveRecord::Migration
  def self.up
    add_index :measurements, [:value_id, :value_type]
    add_index :measurements, :value_type
  end

  def self.down
    remove_index :measurements, [:value_id, :value_type]
    remove_index :measurements, :value_type
  end
end
