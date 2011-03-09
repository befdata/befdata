class AddObservationColumnToMeasurement < ActiveRecord::Migration
  def self.up
    add_column :measurements, :observation_id, :integer
  end

  def self.down
    remove_column :measurements, :observation_id
  end
end
