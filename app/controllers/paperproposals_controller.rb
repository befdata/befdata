class PaperproposalsController < ApplicationController
  include PaperproposalsHelper

  before_filter :load_proposal, :except => [:index, :index_csv, :new, :create, :update_vote]
  before_filter :load_vote, :only => [:update_vote]

  skip_before_filter :deny_access_to_all

  access_control do
    actions :index do
      allow all
    end
    actions :show do
      allow all, :if => :proposal_is_accepted?
      allow logged_in
    end
    actions :new, :create, :index_csv do
      allow logged_in
    end
    actions :edit, :update, :edit_files, :update_state do
      allow :admin, :data_admin
      allow logged_in, :if => :author_may_edit?
    end
    actions :edit_datasets, :update_datasets do
      allow :admin, :data_admin
      allow logged_in, :if => :author_may_edit_datasets?
    end
    actions :safe_delete do
      allow :admin, :data_admin
      allow logged_in, :if => :is_paperproposal_author?
    end
    actions :update_vote do
      allow :admin, :data_admin
      allow logged_in, :if => :is_users_vote
    end
    actions :administrate_votes, :admin_approve_all_votes, :admin_reset_all_votes, :admin_hard_reset do
      allow :admin, :data_admin
    end
  end

  def index
    respond_to do |format|
      format.html { @paperproposals = Paperproposal.includes(:author, :proponents, :main_aspect_dataset_owners, :side_aspect_dataset_owners, :authored_by_project) }
      format.csv {
        send_data generate_csv_index, :type => "text/csv", :disposition => 'attachment',
                  :filename=>"paperproposals-list-for-#{current_user.login}.csv"
      }
    end
  end

  def new
    @paperproposal = Paperproposal.new
    @paperproposal.author = current_user
    @paperproposal.authored_by_project = current_user.projects.first
  end

  def create
    @paperproposal = Paperproposal.new(params[:paperproposal])
    @temp_proponents = User.where(id: params[:people]) #doesn't save it - workaround so they don't get lost when form is not filled correctly
    if @paperproposal.save
      @paperproposal.proponents = User.where(id: params[:people])
      redirect_to edit_datasets_paperproposal_path(@paperproposal)
    else
      render :action => :new
    end
  end

  def show
    respond_to do |format|
      format.html
        @freeformats = @paperproposal.freeformats.order('is_essential DESC, file_file_name ASC')
      format.csv do
        hash = generate_datasets_csv
        user = current_user.try(:login) || "Anonymous-user"
        filename = "pp-#{@paperproposal.id}_#{hash[:count]}-of-#{@paperproposal.datasets.count}-datasets_for-#{user}.csv"
        send_data hash[:csv], :type => 'text/csv', :filename => filename, :disposition => 'attachment'
      end
    end
  end

  def edit
  end

  def update
    @temp_proponents = User.where(id: params[:people]) #doesn't save it - workaround so they don't get lost when form is not filled correctly
    if @paperproposal.update_attributes(params[:paperproposal])
      @paperproposal.proponents = User.where(id: params[:people])
      redirect_to paperproposal_path(@paperproposal)
    else
      render :action => :edit
    end
  end

  def edit_files
    @freeformats = @paperproposal.freeformats
  end

  def edit_datasets
    @datasets = @paperproposal.includes_datasets? ? @paperproposal.datasets : current_cart.datasets
    @datasets = @datasets.sort_by(&:title)
    @all_datasets = Dataset.all :order => 'title'
  end

  def update_datasets
    msg = @paperproposal.update_datasets params[:datasets] || []
    flash[:notice] = 'Datasets have been updated. ' + msg.to_s
    redirect_to @paperproposal
  end

  def administrate_votes
    @votes_type_text = case @paperproposal.board_state
                         when 'submit'
                           'Project Board Votes'
                         when 'accept'
                           'Data Owners Votes'
                         else
                           'No open votes'
                       end
    @votes = select_current_votes
  end

  def admin_approve_all_votes
    select_current_votes.each do |v|
      v.update_attribute :vote, 'accept'
    end
    @paperproposal.check_votes
    flash[:notice] = 'All current votes approved'
    redirect_to @paperproposal
  end

  def admin_reset_all_votes
    select_current_votes.each do |v|
      v.update_attribute :vote, 'none'
    end
    flash[:notice] = 'All current votes reset'
    redirect_to @paperproposal
  end

  def admin_hard_reset
    flash[:notice] = 'Paperproposal has been resetted: ' + @paperproposal.hard_reset
    redirect_to @paperproposal
  end

  # submit to board / re-request data / reset when expired
  def update_state
    flash[:notice] = @paperproposal.user_changes_state
    redirect_to @paperproposal
  end

  # handles a vote
  def update_vote
    @vote.update_attributes(params[:paperproposal_vote])
    if @vote.save
      @vote.paperproposal.check_votes
      flash[:notice] = 'Your vote was submitted'
    else
      flash[:error] = @vote.errors
    end
    redirect_to :back
  end

  # let the user only delete in prep-state / otherwise flag for deletion, so admin can delete
  def safe_delete
    flash[:notice] = @paperproposal.safe_delete(current_user)
    redirect_to paperproposals_path
  end

private

  def generate_csv_index
    paperproposals = Paperproposal.joins(:author).order('state ASC, project_id ASC, created_at ASC')

    CSV.generate(:force_quotes => true) do |csv|
      csv << ['State', 'Project', 'Date created', 'Authors', 'Title', 'Initial title', 'Envisaged journal',
              'Envisaged date','Rationale', 'Comment','Url', 'Published Papers and URIs']

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
                  "#{download_freeformat_url(ff, user_credentials: current_user.try(:single_access_token))} (#{ff.uri})"}.join(' / ')
        ]
      end
    end
  end

  def generate_datasets_csv
    ds_count = 0
    csv = CSV.generate(:force_quotes => true) do |csv|
      csv << ['ID', 'Title', 'Dataset Url', 'CSV download']
      @paperproposal.datasets.order('title ASC').each do |ds|
        if ds.can_download_by?(current_user)
          csv << [ds.id, ds.title, dataset_url(ds),
                  download_dataset_url(ds, :csv, separate_category_columns: true, user_credentials: current_user.try(:single_access_token))]
          ds_count += 1
        end
      end
    end
    {:count => ds_count, :csv => csv}
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

  def is_users_vote
    defined? vote && @vote.user == current_user
  end

  def load_proposal
    @paperproposal = Paperproposal.find(params[:id])
  end

  def load_vote
    @vote = PaperproposalVote.find(params[:id])
  end
end
