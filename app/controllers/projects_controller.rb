class ProjectsController < ApplicationController

skip_before_filter :deny_access_to_all
  access_control do
    actions :index, :show do
      allow all
    end
  end

  def index
    @projects = Project.find(:all, :order => "shortname")
  end

  def show
    @project = Project.find(params[:id])
  end
end
