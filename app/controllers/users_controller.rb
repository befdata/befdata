# This controller handles all calls for staff information.

class UsersController < ApplicationController
  before_filter :load_user, :only => [:show, :edit, :destroy, :update]
  skip_before_filter :deny_access_to_all
  access_control do
    actions :index, :show do
      allow all
    end
    actions  :new, :create, :destroy, :edit, :update do
      allow :admin
    end
  end

  def index
    @users = User.select('id, firstname, lastname, salutation, email, avatar_file_name, alumni')
                  .order('lower(lastname) asc, lower(firstname) asc')
    respond_to do |format|
      format.html
      format.xml
    end
  end

  def show
    @datasets_owned = @user.datasets_owned.sort_by {|d| d.title.to_s}
    @datasets_with_responsible_datacolumns_not_owned = @user.datasets_with_responsible_datacolumns - @datasets_owned
    @project_roles = @user.projectroles
    @paperproposals = @user.paperproposals
  end

  def new
    @user = User.new()
  end

  def create
    @user = User.new(params[:user])
    if @user.save
      @user.projectroles = params[:roles]
      redirect_to user_path(@user), :notice => "Successfully Created user #{@user.to_label}"
    else
      render :action => :new
    end
  end

  def edit
    @project_roles = @user.projectroles.collect{|r|{ role_name: r.name, project_id: r.authorizable_id} }
  end

  def update
    if @user.update_attributes(params[:user])
      @user.projectroles = params[:roles]
      redirect_to user_path(@user), :notice => "Saved successfully"
    else
      render :edit
    end
  end

  def destroy
    user_name = @user.full_name
    if @user.destroy
      redirect_to users_path, :notice => "Successfully deleted #{user_name}"
    else
      flash[:error] = @user.errors.full_messages.to_sentence
      redirect_to :back
    end
  end

private
  def load_user
    @user = User.find(params[:id])
  end
end
