# This controller handles all calls for staff information.

class UsersController < ApplicationController
  before_filter :require_user, :only => [:edit]

  # Whenever a logged in user wants to change its profile information, this action is responsible.
  def edit
    @user = current_user
    if @user.has_role?("admin")
#      @project_board_votes = @user.project_board_votes
#      #ToDo make it better, better scope, soon with rails 3
#      @project_board_votes.reject!{|element| element.data_request.board_state == "accept" ||
#                                             element.data_request.board_state == "final"}
#      @to_vote = @user.for_data_request_votes
#      #ToDo make it better, better scope, soon with rails 3
#      @to_vote.reject!{|element| element.data_request.board_state == "final"}
#      @data_requests = DataRequest.find_all_by_board_state("submit")
    end
  end

end
