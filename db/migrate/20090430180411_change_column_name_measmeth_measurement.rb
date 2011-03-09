class ChangeColumnNameMeasmethMeasurement < ActiveRecord::Migration

  def self.up
    rename_column :measurements, :measurement_methodstep_id, :measurements_methodstep_id
  end

  def self.down
    rename_column :measurements, :measurements_methodstep_id, :measurement_methodstep_id
  end
end
