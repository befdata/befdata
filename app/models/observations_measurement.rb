# ObservationMeasurement entries link Observation entries to
# Measurement entries. The extra table makes a n:n link possible, so
# that each Measurement may be used in more than one Observation.

class ObservationsMeasurement < ActiveRecord::Base
  # belongs_to :observation
  # belongs_to :measurement
end
