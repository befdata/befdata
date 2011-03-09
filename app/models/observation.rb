# Observations are indexed groups of Measurement entries, that
# inherently belong together. By default they have information on
# * location
# * taxonomic entity
# * date, or datetime
#
# Observations may have many ObservationMeasurement entries. This is
# how they are linked to the Measurement entries.

class Observation < ActiveRecord::Base
  belongs_to :location
  # has_many :observations_measurements
  has_many :measurements # , :through => :observations_measurements

  before_destroy :check_if_empty

  def check_if_empty
    unless self.measurements.length == 0 
      errors.add_to_base "Cannot destroy Observation with Data Cells associations"
      false
    end
  end
end
