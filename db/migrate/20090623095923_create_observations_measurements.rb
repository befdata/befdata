class CreateObservationsMeasurements < ActiveRecord::Migration
  def self.up
    create_table :observations_measurements do |t|
      t.integer :observation_id
      t.integer :measurement_id
      t.text :comment

      t.timestamps
    end
  end

  def self.down
    drop_table :observations_measurements
  end
end
