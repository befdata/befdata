# This controller handles all calls for staff information.

class UsersController < ApplicationController
  before_filter :load_current_user, :except => [:index, :show]
  skip_before_filter :deny_access_to_all

  access_control do
    actions :index, :show do
      allow all
    end
    actions :edit, :update, :update_credentials, :votes, :votes_history do
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
      render :edit
    end
  end

  def update_credentials
    # Updates the user credentials with a new random generated, 15 charachter long hex string.
    @user.update_attributes(:single_access_token => SecureRandom.hex(15))
    redirect_to :profile, :notice => "Updated successfully!"
  end 

  def votes
    @project_board_votes = @user.project_board_votes.reject{|vote|
      vote.paperproposal.board_state == ("accept" || "final") || (vote.vote != 'none')}
    @project_board_votes.sort_by!(&:paperproposal)

    @dataset_votes = @user.for_paperproposal_votes.reject{|vote|
      vote.paperproposal.board_state == "final" || (vote.vote != 'none')}
    @dataset_votes.sort_by!(&:paperproposal)
  end

  def votes_history
    @given_votes = @user.paperproposal_votes.where("vote <> 'none'").order("updated_at DESC")
  end

private

  def load_current_user
    @user = current_user
  end

end
