class DataRequestVote < ActiveRecord::Base
  belongs_to :person
  belongs_to :data_request

  validates_uniqueness_of :data_request_id, :scope => [:person_id, :project_board_vote]
end
