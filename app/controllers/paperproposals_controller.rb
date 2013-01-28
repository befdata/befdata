class PaperproposalsController < ApplicationController

  before_filter :load_proposal, :except => [:index, :new, :create, :update_vote]

  skip_before_filter :deny_access_to_all

  access_control do
    actions :index, :show do
      allow all
    end
    actions :new, :create do
      allow logged_in
    end
    actions :edit, :destroy, :update, :update_state, :edit_files, :edit_datasets, :update_datasets do
      allow :admin # TODO should we allow data_admin, too
      allow logged_in # TODO for now, then only allow the author to update / also the other proponents? / not the ones from the datasets
    end
    actions :update_vote do
      allow :admin
      allow logged_in # TODO only the ones who can vote, and then only their own vote
    end
  end

  def index
    @paperproposals = Paperproposal.all
  end

  def show
    @freeformats = @paperproposal.freeformats
  end

  def new
    @paperproposal = Paperproposal.new
    @paperproposal.author = current_user
    @paperproposal.authored_by_project = current_user.projects.first
    @all_persons = User.order("lastname ASC, firstname ASC")
  end

  def create
    @paperproposal = Paperproposal.new(params[:paperproposal])
    @paperproposal.initial_title = @paperproposal.title
    update_proponents

    unless @paperproposal.save
      flash[:error] = @paperproposal.errors.full_messages.to_sentence
      redirect_to :back
    else
      redirect_to edit_datasets_paperproposal_path(@paperproposal)
    end
  end

  def edit
    @all_persons = User.all
    @used_persons = @paperproposal.authors
  end

  def update
    @paperproposal.update_attributes(params[:paperproposal])
    if @paperproposal.save
      update_proponents
      redirect_to paperproposal_path(@paperproposal)
    else
      flash[:error] = @paperproposal.errors.full_messages.to_sentence
      redirect_to :back
    end
  end

  def edit_files
    @freeformats = @paperproposal.freeformats
  end

  def edit_datasets
    @datasets = @paperproposal.datasets.empty? ? current_cart.datasets : @paperproposal.datasets
    @datasets = @datasets.sort_by(&:title)
    @all_datasets = Dataset.all :order => 'title'
  end

  def update_datasets
    @paperproposal.update_attributes(params[:paperproposal])
    if params[:aspect]
      params[:aspect].each do |k, v|
        ds_pp = @paperproposal.dataset_paperproposals.where('dataset_id = ?', k).first
        ds_pp.aspect = v
        ds_pp.save
      end
    end
    @paperproposal.calculate_datasets_proponents
    redirect_to @paperproposal
  end

  # submit to board - switch from prep state to submit state
  def update_state
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
      redirect_to profile_path
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
    redirect_to votes_profile_path
  end

  # ToDo Perhapse dont destroy a data request when he is final?!
  def destroy
    @paperproposal.destroy
    redirect_to :paperproposals
  end

private

  def update_proponents
    proponents = User.find_all_by_id(params[:people]).map{|person| AuthorPaperproposal.new(:user => person, :kind => "user")}
    AuthorPaperproposal.delete_all(["paperproposal_id = ? AND kind = ?", @paperproposal.id, 'user'])
    @paperproposal.author_paperproposals << proponents
  end

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
      flash[:errors] = @paperproposal.errors.full_messages.to_sentence
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

  def load_proposal
    @paperproposal = Paperproposal.find(params[:id])
  end
end
