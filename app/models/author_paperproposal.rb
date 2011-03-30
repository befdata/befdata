class AuthorPaperproposal < ActiveRecord::Base
  belongs_to :user
  belongs_to :paperproposal

  validates_uniqueness_of :user_id, :scope => [:paperproposal_id, :kind]
end
