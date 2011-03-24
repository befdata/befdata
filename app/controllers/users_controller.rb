# This controller handles all calls for staff information.

class UsersController < ApplicationController
  before_filter :require_user, :only => [:edit]


  # The index method simply lists all staff members, ordered by their last name.
  def index
    @users = User.find(:all, :order => "lastname")
  end

  # Whenever a logged in user wants to change its profile information, this action is responsible.
  def edit
    @user = current_user
    if @user.has_role?("admin")
      @project_board_votes = @user.project_board_votes
      #ToDo make it better, better scope, soon with rails 3
      @project_board_votes.reject!{|element| element.paperproposal.board_state == "accept" ||
                                             element.paperproposal.board_state == "final"}
      @to_vote = @user.for_paperproposal_votes
      #ToDo make it better, better scope, soon with rails 3
      @to_vote.reject!{|element| element.paperproposal.board_state == "final"}
      @data_requests = Paperproposal.find_all_by_board_state("submit")
    end
  end

  # The show method provides all informations about one specific person.
  def show

    redirect_to(:action => "index") and return if params[:id].blank?
    first, last = params[:id].split(/_/)
    @user = User.find(:first, :conditions => ["firstname = ? and lastname = ?", first, last])
    return redirect_to(:action => "index", :status => :not_found) unless @user
  end


end
