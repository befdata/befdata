# This controller handles all calls for staff information.

class UsersController < ApplicationController
  before_filter :load_user, :only => [:show, :edit, :destroy, :update]
  skip_before_filter :deny_access_to_all
  access_control do
    actions :index, :show do
      allow all
    end
    actions  :new, :create, :edit, :update, :destroy do
      allow :admin
    end
  end

  def index
    @users = User.all :order => "lastname"
  end

  def show
    @datasets_owned = @user.datasets_owned.sort_by {|d| d.title.to_s}
    @datasets_with_responsible_datacolumns_not_owned = @user.datasets_with_responsible_datacolumns - @datasets_owned
    @project_roles = @user.projectroles
    @paperproposals = @user.paperproposals
    @deletable = (@datasets_owned.count + @paperproposals.count +
                  @datasets_with_responsible_datacolumns_not_owned.count) == 0
  end

  def new
    @user = User.new()
  end
  def create
    @user = User.new(params[:user])
    if @user.save
      # assign roles of projects
      unless params[:roles].blank?
        params[:roles].each do |role|
          @user.has_role!(role[:type], Project.find(role[:value])) unless role[:value].blank?
        end
      end
      redirect_to user_path(@user), :notice => "Successfully Created user #{@user.to_label}"
    else
      render :action => :new
    end
  end
  def update
    if @user.update_attributes(params[:user])
      # assign roles of projects
      @user.has_no_roles_for!(Project)
      unless params[:roles].blank?
        params[:roles].each do |role|
          @user.has_role!(role[:type], Project.find(role[:value])) unless role[:value].blank?
        end
      end
      redirect_to user_path(@user), :notice => "Saved successfully"
    else
      render :edit
    end
  end

  def destroy
    name = @user.to_label
    if @user.destroy
      redirect_to users_path, :notice => "Successfully deleted #{name}"
    else
      redirect_to :back, :error => @user.errors.full_messages.to_sentence
    end
  end


private
  def load_user
    @user = User.find(params[:id])
  end
end
