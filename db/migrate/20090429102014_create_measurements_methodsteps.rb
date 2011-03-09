class CreateMeasurementsMethodsteps < ActiveRecord::Migration
  def self.up
    create_table :measurements_methodsteps do |t|
      t.integer :methodstep_id
      t.integer :context_id
      t.string :columnheader
      t.integer :columnnr
      t.text :definition
      t.string :unit
      t.string :missingcode
      t.text :comment

      t.timestamps
    end
  end

  def self.down
    drop_table :measurements_methodsteps
  end
end
