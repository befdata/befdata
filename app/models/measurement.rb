# Measurement entries are pointing at the raw data obtained from
# measuring something. Each row in this table will link to different
# tables, depending on the type of data:
# * Numericvalue
# * Categoricvalue
# * Datetimevalue
# * PersonRole
# * Textvalue
#
# The rows contain the id for each of the table, and the table name,
# under which the value is saved.
#
# One measurement can link to more than one Observation entries
# through the table ObservationsMeasurement. But in most of the cases,
# one Measurement will belong to only one Observation.

class Measurement < ActiveRecord::Base
  # has_many :observations_measurements
  # linking to more than one observation is deprecated
  # has_many :observations, :through => :observations_measurements
  
  belongs_to :observation, :dependent => :destroy
  belongs_to :measurements_methodstep

  # this seems to be the "child" row when coming from the valuetypes
  belongs_to :value, :polymorphic => :true, :dependent => :destroy
  belongs_to :datetimevalue, :class_name => "Datetimevalue", :foreign_key => "value_id"
  belongs_to :textvalue, :class_name => "Textvalue", :foreign_key => "value_id"
  belongs_to :numericvalue, :class_name => "Numericvalue", :foreign_key => "value_id"
  belongs_to :categoricvalue, :class_name => "Categoricvalue", :foreign_key => "value_id"
  belongs_to :filevalue, :class_name => "Filevalue", :foreign_key => "value_id"



  def same_entry_cells
    entry = self.import_value
    data_column = self.measurements_methodstep
    all_cells = data_column.measurements
    same_entry_cells = all_cells.
      select{|cell|  cell.import_value == entry}.flatten
    return same_entry_cells
  end 

end
