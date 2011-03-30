class PaperproposalVote < ActiveRecord::Base
  belongs_to :user
  belongs_to :paperproposal

  validates_uniqueness_of :paperproposal_id, :scope => [:user_id, :project_board_vote]
  
end
