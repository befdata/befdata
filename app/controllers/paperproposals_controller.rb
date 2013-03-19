class PaperproposalsController < ApplicationController
  helper FreeformatsHelper

  before_filter :load_proposal, :except => [:index, :index_csv, :new, :create, :update_vote]
  before_filter :load_vote, :only => [:update_vote]

  skip_before_filter :deny_access_to_all

  access_control do
    actions :index do
      allow all
    end
    actions :show do
      allow all, :if => :proposal_is_accepted
      allow logged_in
    end
    actions :new, :create, :index_csv do
      allow logged_in
    end
    actions :edit, :update, :update_state, :edit_datasets, :update_datasets do
      allow :admin
      allow :data_admin
      allow logged_in, :if => :author_may_edit
    end
    actions :edit_files, :destroy do
      allow :admin
      allow :data_admin
      allow logged_in, :if => :paperproposal_author
    end
    actions :update_vote do
      allow :admin
      allow logged_in, :if => :is_users_vote
    end
    actions :administrate_votes, :admin_approve_all_votes, :admin_reset_all_votes do
      allow :admin
    end
  end

  def index
    @paperproposals = Paperproposal.all
  end

  def index_csv
    send_data generate_csv_index, :type => "text/csv", :filename=>"paperproposals-list-for-#{current_user.login}.csv", :disposition => 'attachment'
  end

  def show
    @freeformats = @paperproposal.freeformats.order('is_essential DESC, file_file_name ASC')
  end

  def administrate_votes
    @votes_type_text = case @paperproposal.board_state
                         when 'submit'
                           'Project Board Votes'
                         when 'accept'
                           'Main Proponent Votes'
                         else
                           'No open votes'
                       end
    @votes = select_current_votes
  end

  def admin_approve_all_votes
    select_current_votes.each do |v|
      v.update_attribute :vote, 'accept'
      v.save
      @paperproposal.handle_vote v
    end
    flash[:notice] = 'All current votes appreoved'
    redirect_to @paperproposal
  end

  def admin_reset_all_votes
    select_current_votes.each do |v|
      v.update_attribute :vote, 'none'
    end
    flash[:notice] = 'All current votes reset'
    redirect_to @paperproposal
  end

  def new
    @paperproposal = Paperproposal.new
    @paperproposal.author = current_user
    @paperproposal.authored_by_project = current_user.projects.first
  end

  def create
    @paperproposal = Paperproposal.new(params[:paperproposal])
    @paperproposal.initial_title = @paperproposal.title
    @temp_proponents = User.find_all_by_id(params[:people]) #doesn't save it - workaround so they don't get lost when form is not filled correctly
    if @paperproposal.save
      @paperproposal.update_proponents params[:people]
      redirect_to edit_datasets_paperproposal_path(@paperproposal)
    else
      render :action => :new
    end
  end

  def edit
  end

  def update
    @paperproposal.update_attributes(params[:paperproposal])
    @temp_proponents = User.find_all_by_id(params[:people]) #doesn't save it - workaround so they don't get lost when form is not filled correctly
    if @paperproposal.save
      @paperproposal.update_proponents params[:people]
      redirect_to paperproposal_path(@paperproposal)
    else
      render :action => :edit
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
    dataset_ids = params[:dataset_ids] ? params[:dataset_ids] : []
    @paperproposal.update_attributes(:dataset_ids => dataset_ids)
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
    if params[:paperproposal][:board_state] == 'submit'
      @paperproposal.submit_to_board
      flash[:notice] = 'Submitted to Project Board'
    else
      flash[:error] = 'Something went wrong'
    end
    redirect_to @paperproposal
  end

  # handles a vote
  def update_vote
    @vote.update_attributes(params[:paperproposal_vote])
    if @vote.save
      @vote.paperproposal.handle_vote @vote
      flash[:notice] = 'Your vote was submitted'
    else
      flash[:error] = @vote.errors
    end

    redirect_to :back
  end

  # ToDo Perhapse dont destroy a data request when he is final?! / let the user only delete in prep-state / otherwise flag for deletion
  def destroy
    @paperproposal.destroy
    redirect_to :paperproposals
  end

private

  def generate_csv_index
    paperproposals = Paperproposal.joins(:author).order('state ASC, project_id ASC, created_at ASC')

    CSV.generate(:force_quotes => true) do |csv|
      csv << ['State', 'Project', 'Date created', 'Authors', 'Title', 'Initial title', 'Envisaged journal',
              'Envisaged date','Rationale', 'Comment','Url', 'Essential files and URIs']

      paperproposals.each do |pp|
        csv << [pp.state,
                pp.authored_by_project.blank? ? '' : pp.authored_by_project.name,
                pp.created_at.year,
                pp.all_authors_ordered.map{|u| u.to_s}.join(', '),
                pp.title, pp.initial_title, pp.envisaged_journal,
                pp.envisaged_date.blank? ? '' : pp.envisaged_date.year,
                pp.rationale, pp.comment,
                paperproposal_url(pp),
                pp.freeformats.where('is_essential = TRUE').order('file_file_name ASC').map{|ff|
                  "#{view_context.complete_freeformat_url(ff, true)} (#{ff.uri})"}.join(' / ')
        ]
      end
    end
  end

  def select_current_votes
    case @paperproposal.board_state
      when 'submit'
        @paperproposal.project_board_votes
      when 'accept'
        @paperproposal.for_data_request_votes
      else
        []
    end
  end

  def proposal_is_accepted
    defined? @paperproposal && @paperproposal.state == 'accepted'
  end

  def paperproposal_author
    @paperproposal.author == current_user
  end

  def author_may_edit
    paperproposal_author && @paperproposal.board_state == ('prep' || 're_prep' || 'final')
  end

  def is_users_vote
    @vote.user == current_user
  end

  def load_proposal
    @paperproposal = Paperproposal.find(params[:id])
  end

  def load_vote
    @vote = PaperproposalVote.find(params[:id])
  end
end
