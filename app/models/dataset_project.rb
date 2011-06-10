class DatasetProject < ActiveRecord::Base
  belongs_to :dataset
  belongs_to :project
end
