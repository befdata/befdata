class ProfilesController < ApplicationController
  before_filter :load_current_user
  skip_before_filter :deny_access_to_all

  access_control do
    allow logged_in
  end

  def show
    @datasets_owned = @user.datasets_owned.sort_by {|d| d.title.to_s}
    @datasets_with_responsible_datacolumns_not_owned = @user.datasets_with_responsible_datacolumns - @datasets_owned
    @project_roles = @user.projectroles
    @paperproposals = @user.paperproposals
  end
  
  def update
    if @user.update_attributes(params[:user].slice(:login, :password, :password_confirmation, :firstname,
            :middlenames, :lastname, :email, :salutation, :institution_name, :institution_url, :institution_phone,
            :institution_fax, :url, :country, :city, :street, :comment, :avatar))
      redirect_to profile_path, :notice => "Saved successfully"
    else
      render :edit
    end
  end

  def update_credentials
    @user.reset_single_access_token!
    respond_to do |format|
      format.html { redirect_to :profile, :notice => "Your login credentials was updated successfully!" }
      format.js
    end
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
