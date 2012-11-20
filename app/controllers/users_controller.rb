# This controller handles all calls for staff information.

class UsersController < ApplicationController
  before_filter :require_user, :except => [:index, :show]
  before_filter :load_current_user, :except => [:index, :show]

  skip_before_filter :deny_access_to_all

  access_control do
    actions :index, :show do
      allow all
    end
    actions :edit, :update, :votes do
      allow logged_in
    end
  end

  def index
    @users = User.all :order => "lastname"
  end

  def show
    @user = params[:id].nil? ? current_user : User.find(params[:id])
    if @user.nil?
      flash[:error] = "You must be logged in to access this page"
      redirect_to :root and return
    else
      @user_datasets_owned = @user.datasets_owned.sort_by {|d| d.title.to_s}
    end
  end

  def edit
  end

  def update
    if @user.update_attributes(params[:user])
      redirect_to :profile, :notice => "Saved successfully!"
    else
      flash[:error]=@user.errors.full_messages.to_sentence
      redirect_to :back
    end
  end

  def votes
    @project_board_votes = @user.project_board_votes
    #ToDo make it better, better scope, soon with rails 3
    @project_board_votes.reject!{|element| element.paperproposal.board_state == "accept" ||
        element.paperproposal.board_state == "final"}
    @project_board_votes.sort!{|a,b| a.paperproposal <=> b.paperproposal}

    @to_vote = @user.for_paperproposal_votes
    #ToDo make it better, better scope, soon with rails 3
    @to_vote.reject!{|element| element.paperproposal.board_state == "final"}
    @to_vote.sort!{|a,b| a.paperproposal <=> b.paperproposal}

    @data_requests = Paperproposal.find_all_by_board_state("submit").sort
  end

private

  def load_current_user
    @user = current_user
  end

  # checks whether the user to be edited/updated is current user
  def correct_user
    user_id = params[:id]
    return(false) if user_id && (user_id.to_i != current_user.id)
    return(true)
  end
end
