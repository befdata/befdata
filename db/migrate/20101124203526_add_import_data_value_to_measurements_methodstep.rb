class AddImportDataValueToMeasurementsMethodstep < ActiveRecord::Migration
  def self.up
    add_column :measurements_methodsteps, :import_data_type, :string
  end 

  def self.down
    remove_column :measurements_methodsteps, :import_data_type
  end
end
