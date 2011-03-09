class DataRequestContext < ActiveRecord::Base
  belongs_to :data_request
  belongs_to :context
end
