class AuthorDataRequest < ActiveRecord::Base
  belongs_to :person
  belongs_to :data_request

  validates_uniqueness_of :person_id, :scope => [:data_request_id, :kind]
end
