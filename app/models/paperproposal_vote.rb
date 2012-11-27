# This file organises the communications between users (User) and data
# sharing via paperproposals (Paperproposal). It defines the class
# PaperproposalVote.

# Paperproposal votes communicate the opinion of users (User) about
# the state of paperproposals (Paperproposal). Paperproposals are
# essential to data sharing. Users can apply for access to datasets
# (Dataset) by submitting paperproposals. For this proponents of the
# paperproposal shortly scetch their rationale and choose the datasets
# they would like to use. The proposal is then submitted to the
# project board, which are the users with a "project board" Role.
#
# Each user with project board role will now get a PaperproposalVote
# with the attribute "project_board_vote" set to true, and "vote" set
# to "none". She or he can now either reject the submission and
# communicate tipps in the "comment" attributes, or "accept" the
# submission.
# 
# After all project board members have accepted a proposal, the owners
# of the datasets are given paperproposal votes. In this case the
# attribute "project_board vote" is set to false, but the procedure is
# the same: all votes have to be set to "accept" for the datasets to
# allow access for the proponets.
class PaperproposalVote < ActiveRecord::Base
  belongs_to :user
  belongs_to :paperproposal

  validates_uniqueness_of :paperproposal_id, :scope => [:user_id, :project_board_vote]
end
