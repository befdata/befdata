# This controller handles all incoming calls for project pages.

class ProjectsController < ApplicationController

  # Every call for the project index is redirected to the research page
  def index
    @projects = Project.find(:all, :order => "shortname")
    respond_to do |format|
      format.html # index.html.erb
      # format.xml  { render :xml => @projects }
    end
    #    redirect_to root_path + 'research'
  end
  
  # The show action is used, whenever an URL like /projects/1
  # called. As this is a call for a specific project, the database is
  # queried for the page of the project.
  def show
    @project = Project.find(params[:id])

#    logger.debug "@project in projects show"
#    logger.debug @project.inspect
#    @prs = @project.person_roles.uniq
#    dcs = @prs.collect{|pr| pr.measmeths_personroles}.flatten.uniq
#    dss = dcs.collect{|dc| dc.context}.flatten.uniq
#    dss << @prs.collect{|pr| pr.contexts}.flatten.uniq
#    @dss = dss.flatten.uniq
#
#    # members
#    @spe = @project
#    @namee = @spe.name unless @spe.blank?
#
#    @staffe = @spe.person_roles.uniq
#    if @staffe != nil
#      if @staffe.length > 0
#        @pise = @staffe.select{|s| s.role.name == 'pi'}
#        @copise = @staffe.select{|s| s.role.name == 'co-pi'}
#        @postdocse = @staffe.select{|s| s.role.name == 'postdoc'}
#        @phdse = @staffe.select{|s| s.role.name == 'phd'}
#        @technicianse = @staffe.select{|s| s.role.name == 'technician'}
#        @studentse = @staffe.select{|s| s.role.name == 'student'}
#        listed_prs = @pise + @copise + @postdocse + @phdse +
#          @technicianse + @studentse
#        @others = @staffe - listed_prs
#      end
#    end
  end
end
