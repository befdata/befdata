class PaperproposalsController < ApplicationController


  before_filter :require_user, :only => [:index, :new, :create, :destroy, :update, :show]
  before_filter :load_proposal, :only => [:show, :edit, :update, :destroy]

  #####################################
  # Show Part, Prepare for some views
  #####################################

  #show list of data requests
  def index
    @paperproposals = Paperproposal.all
    # .sort_by(&created_at)
  end

  #prepare for new data request
  def new
    @paperproposal = Paperproposal.new
    @paperproposal.author = current_user
    @paperproposal.corresponding = current_user
    # !! Zeitschlucker
    @all_persons = User.all.sort{|a,b| a.to_label <=> b.to_label}

    project = current_user.roles_for(Project).first.try(:authorizable)
    if project
      senior = project.accepted_roles.find_by_name("pi").users.first
      @paperproposal.senior_author = senior
    end
  end

  # prepare for show
  def show

  end

  #prepare for edit data request
  def edit
    @all_persons = User.all
    @used_persons = @paperproposal.authors
    @datasets = Dataset.find(:all, :order => 'title')
    @current_cart = current_cart

    1.times {@paperproposal.filevalues.build}
    
  end

  #######################################
  # Update Part, Get/Post Part for forms
  #######################################

  #create new data request
  def create
    @paperproposal = Paperproposal.new(params[:paperproposal])
    proponents = User.find_all_by_id(params[:people]).
        map{|person| AuthorPaperproposal.new(:user => person, :kind => "user")}
    @paperproposal.author_paperproposals = proponents
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
    @paperproposal.update_attributes(params[:paperproposal])
    @paperproposal.save

    @paperproposal.dataset_paperproposals.clear if ( params[:datasets].nil? && params[:paperproposal].nil? )
    if params[:datasets]
      @datasets = Dataset.find(params[:datasets])
      @paperproposal.datasets= @datasets
    end
    update_aspects if params[:aspect]
    update_author_list(@paperproposal)
    redirect_to edit_paperproposal_path(@paperproposal)
  end

  # submit to board - switch from prep state to submit state
  def update_state
    @paperproposal = Paperproposal.find(params[:id])
    pre_state = @paperproposal.board_state
    @paperproposal.update_attributes(params[:paperproposal])
    @paperproposal.lock = true
    @paperproposal.save

    #submit again
    if pre_state == "re_prep" && @paperproposal.board_state == "submit"
      @paperproposal.paperproposal_votes.each{|element| element.update_attribute(:vote, "none")}
    end

    project_board_role = Role.find_by_name("project_board")
    users =  project_board_role.users
    users.each{|user| @paperproposal.paperproposal_votes << PaperproposalVote.new(:user => user, :project_board_vote => true)}

    redirect_to @paperproposal
  end

  # after one person vote, here the attributes for this data request is changed
  def update_vote
    @to_vote = PaperproposalVote.find(params[:id])
    @to_vote.update_attributes(params[:paperproposal_vote])
    @paperproposal = @to_vote.paperproposal

    unless @to_vote.save
      flash[:error] = @to_vote.errors
      redirect_to :profile
    end

    if @to_vote.vote == "reject"
      @paperproposal.board_state = "re_prep"
      @paperproposal.lock = false
      @paperproposal.save
    end

    all_none_votes = @paperproposal.paperproposal_votes.select{|vote| vote.vote == "none"}
    all_reject_votes = @paperproposal.paperproposal_votes.select{|vote| vote.vote == "reject"}

    if all_none_votes.empty? & all_reject_votes.empty?
      case @paperproposal.board_state
        when "submit"
          prepare_data_request_for_accept_state
        when "accept"
          @paperproposal.board_state = "final"
          @paperproposal.lock = false
          @paperproposal.save
          @paperproposal.datasets.each do |context|
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
    redirect_to :paperproposals
  end

private

  # After accept from project board, all authors from current data request will be add
  # that they accept this data request
  def prepare_data_request_for_accept_state
    authors_of_data_columns_request = @paperproposal.author_paperproposals
      # Todo erstmal alle
      #.select{|element| element.kind == "main"}
    data_request_votes = authors_of_data_columns_request.
          map{|adr| PaperproposalVote.new(:user => adr.user, :project_board_vote => false)}
    @paperproposal.paperproposal_votes << data_request_votes
    @paperproposal.board_state = "accept"
    unless @paperproposal.save
      flash[:errors] = @paperproposal.errors.full_messages
    end
  end

  def update_author_list(data_request)
    auto_generated_adrs = data_request.author_paperproposals.select{|join| join.kind == "context" ||
                                                                          join.kind == "main" ||
                                                                          join.kind == "side"}
    auto_generated_adrs.each{|element| element.destroy}


    data_request.dataset_paperproposals.each do |element|
      owner_of_context = element.dataset.users.select{|e| e.has_role? :owner, element.dataset}
      author_array = owner_of_context.
          map{|e| AuthorPaperproposal.new(:user=> e,
                                        :paperproposal => data_request,
                                        :kind => "main")}
      data_request.author_paperproposals << author_array
      element.dataset.datacolumns.each do |e|
        author_array = e.users.
          map{|e| AuthorPaperproposal.new(:user => e,
                                          :paperproposal => data_request,
                                          :kind => "ack")}
        data_request.author_paperproposals << author_array
      end
    end

  end

  def update_aspects
    logger.debug 'in update aspects'
    logger.debug 'paperproposal: ' + @paperproposal.inspect
    @paperproposal.dataset_paperproposals.each do |paperproposal_dataset|
      logger.debug 'params[:aspect]: ' + params[:aspect].inspect
      logger.debug 'paperproposal_dataset: ' + paperproposal_dataset.inspect
      paperproposal_dataset.aspect = params[:aspect].fetch("#{paperproposal_dataset.dataset_id}")
      paperproposal_dataset.save
    end
  end

  def load_proposal
    @paperproposal = Paperproposal.find(params[:id])
  end





end
