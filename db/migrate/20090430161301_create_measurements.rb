class CreateMeasurements < ActiveRecord::Migration
  def self.up
    create_table :measurements do |t|
      t.integer :measurement_methodstep_id
      t.integer :value_id
      t.string :value_type
      t.integer :rownr
      t.text :comment

      t.timestamps
    end
  end

  def self.down
    drop_table :measurements
  end
end
