# This model is currently unused. It will serve as a place to store location informations of Observation.
class Location < ActiveRecord::Base
  has_many :observations
  has_many :regioncoords
end
