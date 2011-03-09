# This controller handles all calls for staff information.

class PersonsController < ApplicationController

  # The index method simply lists all staff members, ordered by their last name.
  def index
    @people = Person.find(:all, :order => "lastname")
  end

  # The show method provides all informations about one specific person.
  def show
    redirect_to(:action => "index") and return if params[:path_name].blank?
    first, last = params[:path_name].split(/_/)
    @person = Person.find(:first, :conditions => ["firstname = ? and lastname = ?", first, last])
    return redirect_to(:action => "index", :status => :not_found) unless @person
  end

  # Whenever a logged in user wants to change its profile information, this action is responsible.
  def edit
    if logged_in?
      @person = Person.find_by_id(session[:user_id]) if session[:user_id]
      if @person.has_role?("admin")
        @project_board_votes = @person.project_board_votes
        #ToDo make it better, better scope, soon with rails 3
        @project_board_votes.reject!{|element| element.data_request.board_state == "accept" ||
                                               element.data_request.board_state == "final"}
        @to_vote = @person.for_data_request_votes
        #ToDo make it better, better scope, soon with rails 3
        @to_vote.reject!{|element| element.data_request.board_state == "final"}
        @data_requests = DataRequest.find_all_by_board_state("submit")
      end
    else
      session[:return_to] = request.request_uri
      redirect_to login_path
    end
  end

  # This action is responsible for storing changed profile values.
  def update
    @person = Person.find_by_id(session[:user_id])

    pwd = params[:person].delete("pwd")
    unless pwd.blank?
      @person.pwd = pwd
    end
    if @person.update_attributes(params[:person])
      flash[:notice] = 'Person was successfully updated.'
      redirect_to :controller => 'profile'
    end
  end

  # This action provides a staff list for a specific Project. 
  def project
    project = Project.find(params[:id])
    @spe = project

    @namee = @spe.name unless @spe.blank?

    @staffe = project.person_roles.uniq
    if @staffe != nil
      if @staffe.length > 0
        @pise = @staffe.select{|s| s.role.name == 'pi'}
        @copise = @staffe.select{|s| s.role.name == 'co-pi'}
        @postdocse = @staffe.select{|s| s.role.name == 'postdoc'}
        @phdse = @staffe.select{|s| s.role.name == 'phd'}
        @technicianse = @staffe.select{|s| s.role.name == 'technician'}
        @studentse = @staffe.select{|s| s.role.name == 'student'}
        listed_prs = @pise + @copise + @postdocse + @phdse +
          @technicianse + @studentse
        @others = @staffe - listed_prs
      end
    else
      redirect_to :back
    end
  end

end
