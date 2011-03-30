class ProjectsController < ApplicationController

  def index
    @projects = Project.find(:all, :order => "shortname")
  end

  def show
    @project = Project.find(params[:id])
  end
end
