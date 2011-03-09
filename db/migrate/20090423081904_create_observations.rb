class CreateObservations < ActiveRecord::Migration
  def self.up
    create_table :observations do |t|
      t.integer :year
      t.integer :month
      t.integer :day
      t.datetime :date
      t.integer :location_id
      t.integer :entity_id
      t.text :comment

      t.timestamps
    end
  end

  def self.down
    drop_table :observations
  end
end
