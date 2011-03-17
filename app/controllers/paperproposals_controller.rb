class PaperproposalsController < ApplicationController


   before_filter :require_user, :only => [:index, :new, :create, :destroy, :update, :show]
  before_filter :load_request, :only => [:show, :edit, :update, :destroy]

  #####################################
  # Show Part, Prepare for some views
  #####################################

  #show list of data requests
  def index
    @data_requests = DataRequest.all
  end

  #prepare for new data request
  def new
    @paperproposal = Paperproposal.new
    @paperproposal.author = current_user
    @paperproposal.corresponding = current_user
    @all_persons = User.all.sort{|a,b| a.to_label <=> b.to_label}

    #TODO PROJECTS
     #project = current_user.projects.first
     #senior = project.query_by_role(:pi).first

    #TODO SENIOR AUTHOR
    #@paperproposal.senior_author = senior
    
    1.times {@paperproposal.filevalues.build}
  end

  # prepare for show
  def show

  end

  #prepare for edit data request
  def edit
    @all_persons = Person.all
    @used_persons = @paperproposal.authors
    @contexts = Context.find(:all, :order => 'title')
    @current_cart = current_cart
  end

  #######################################
  # Update Part, Get/Post Part for forms
  #######################################

  #create new data request
  def create
    @paperproposal = Paperproposal.new(params[:paperproposal])
    author_data_requests = User.find_all_by_id(params[:people]).
        map{|person| AuthorPaperproposal.new(:user => person, :kind => "user")}
    @paperproposal.author_paperproposals = author_data_requests
    @all_persons = User.all
    unless @paperproposal.save
      flash[:error] = @paperproposal.errors.full_messages
      render :action => :new
    else
      redirect_to edit_paperproposal_path(@paperproposal)
    end
  end

  #update attributes and joins for one data request
  def update
    @paperproposal.update_attributes(params[:data_request])
    @paperproposal.save

    @paperproposal.data_request_contexts.clear if ( params[:contexts].nil? && params[:data_request].nil? )
    if params[:contexts]
      @contexts = Context.find(params[:contexts])
      @paperproposal.contexts = @contexts
    end
    update_aspects if params[:aspect]
    update_author_list(@paperproposal)
    redirect_to edit_data_request_path(@paperproposal)
  end

  # submit to board - switch from prep state to submit state
  def update_state
    @paperproposal = DataRequest.find(params[:data_request_id])
    pre_state = @paperproposal.board_state
    @paperproposal.update_attributes(params[:data_request])
    @paperproposal.lock = true
    @paperproposal.save

    #submit again
    if pre_state == "re_prep" && @paperproposal.board_state == "submit"
      @paperproposal.data_request_votes.each{|element| element.update_attribute(:vote, "none")}
    end

    project_board_role = Role.find_by_name("project board")
    persons = Person.find(:all)
    persons.each do |person|
      if person.has_role? :project_board
        @paperproposal.data_request_votes << DataRequestVote.new(:person => person, :project_board_vote => true)
      end
    end
    redirect_to @paperproposal
  end

  # after one person vote, here the attributes for this data request is changed
  def update_vote
    @to_vote = DataRequestVote.find(params[:id])
    @to_vote.update_attributes(params[:data_request_vote])
    @paperproposal = @to_vote.data_request

    unless @to_vote.save
      flash[:error] = @to_vote.errors
      redirect_to :profile
    end

    if @to_vote.vote == "reject"
      @paperproposal.board_state = "re_prep"
      @paperproposal.lock = false
      @paperproposal.save
    end

    all_none_votes = @paperproposal.data_request_votes.select{|vote| vote.vote == "none"}
    all_reject_votes = @paperproposal.data_request_votes.select{|vote| vote.vote == "reject"}

    if all_none_votes.empty? & all_reject_votes.empty?
      case @paperproposal.board_state
        when "submit"
          prepare_data_request_for_accept_state
        when "accept"
          @paperproposal.board_state = "final"
          @paperproposal.lock = false
          @paperproposal.save
          @paperproposal.contexts.each do |context|
            context.accepts_role! :proposer, @paperproposal.author
          end
        else
          #do nothing
      end
    end
    redirect_to :profile
  end

  ######################
  # Destroy Part
  #####################

  # destroy action
  # ToDo Perhapse dont destroy a data request when he is final?!
  def destroy
    @paperproposal.destroy
    redirect_to :data_requests
  end

private

  # After accept from project board, all authors from current data request will be add
  # that they accept this data request
  def prepare_data_request_for_accept_state
    authors_of_data_columns_request = @paperproposal.author_data_requests
      # Todo erstmal alle
      #.select{|element| element.kind == "main"}
    data_request_votes = authors_of_data_columns_request.
          map{|adr| DataRequestVote.new(:person => adr.person, :project_board_vote => false)}
    @paperproposal.data_request_votes << data_request_votes
    @paperproposal.board_state = "accept"
    unless @paperproposal.save
      flash[:errors] = @paperproposal.errors.full_messages
    end
  end

  def update_author_list(data_request)
    auto_generated_adrs = data_request.author_data_requests.select{|join| join.kind == "context" ||
                                                                          join.kind == "main" ||
                                                                          join.kind == "side"}
    auto_generated_adrs.each{|element| element.destroy}


    data_request.data_request_contexts.each do |element|
      owner_of_context = element.context.people.select{|e| e.has_role? :owner, element.context}
      author_array = owner_of_context.
          map{|e| AuthorDataRequest.new(:person => e,
                                        :data_request => data_request,
                                        :kind => "main")}
      data_request.author_data_requests << author_array
      element.context.measurements_methodsteps.each do |e|
        author_array = e.people.
          map{|e| AuthorDataRequest.new(:person => e,
                                          :data_request => data_request,
                                          :kind => "ack")}
        data_request.author_data_requests << author_array
      end
    end

  end

  def update_aspects
    @paperproposal.data_request_contexts.each do |data_request_context|
      data_request_context.aspect = params[:aspect].fetch("#{data_request_context.context_id}")
      data_request_context.save
    end
  end

  def load_request
    @paperproposal = DataRequest.find(params[:id])
  end





end
