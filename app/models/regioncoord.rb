# This model is currently unused. It will serve as a place to store location informations.
class Regioncoord < ActiveRecord::Base
  belongs_to :location
end
