class DatasetsController < ApplicationController

  before_filter :load_dataset, :only => [:download, :show, :edit, :update, :data, :approve_predefined, :clean, :destroy,
                                        :update_dataset_with_only_freeformat_file, :save_dataset_freeformat_tags]


  before_filter :load_freeformat_dataset, :only => [:download_freeformat]

  before_filter :load_dataset_freeformat, :only => [:update_dataset_freeformat_associations]

  rescue_from 'Acl9::AccessDenied', :with => :access_denied

  skip_before_filter :deny_access_to_all
  access_control do
    allow all, :to => [:show, :index, :load_context]

    actions :download, :edit, :update, :data, :update_freeformat_associations, :save_freeformat_associations,
            :update_dataset_with_only_freeformat_file , :save_dataset_freeformat_tags, :update_dataset_freeformat_file,
            :download_freeformat, :save_dataset_freeformat_associations, :approve_predefined do
      allow :admin
      allow :owner, :of => :dataset
      allow :proposer, :of => :dataset
    end

    actions :clean, :destroy do
      allow :admin
      allow :owner, :of => :dataset
    end

    action :download_freeformat, :download do
      allow logged_in, :if => :dataset_is_free_for_members
      allow all, :if => :dataset_is_free_for_public
    end

    actions :create, :upload_freeformat, :create_dataset_with_freeformat_file,
    :create_dataset_freeformat, :update_dataset_freeformat_associations do
      allow logged_in
    end
  end

  def create
    datafile = Datafile.create!(params[:datafile])
    @dataset = Dataset.new
    @dataset.upload_spreadsheet = datafile

    if datafile.valid? && @dataset.save
      current_user.has_role! :owner, @dataset
      @dataset.dataworkbook.portal_users_listed_as_responsible.each do |user|
        user.has_role!(:owner, @dataset)
      end
    else
      flash[:error] = @dataset.errors.full_messages.to_sentence
      flash[:error] << datafile.errors.full_messages.to_sentence
      redirect_to :back
    end

  end

  def update
    users_given_as_provenance = User.find(params[:people]) unless params[:people].blank?
    users_given_as_provenance.each do |user|
      user.has_role! :owner, @dataset
    end

    @dataset.update_attributes(params[:dataset])

    redirect_to data_dataset_path(@dataset) and return
  end

  def data
    @book = Dataworkbook.new(@dataset.upload_spreadsheet)

    return unless @book.columnheaders_unique?

    if @dataset.datacolumns.length == 0
      @book.import_data
      load_dataset #reload
    end
    @predefined_columns = @dataset.predefined_columns
  end

  
  def approve_predefined
    @dataset.approve_predefined_columns(current_user)

    if @dataset.columns_with_invalid_values_after_approving_predefined.blank?
      flash[:notice] = "All available columns were successfully approved."
    else
      flash[:error] = "The following columns had invalid values:
          #{@dataset.columns_with_invalid_values_after_approving_predefined.map{|c| c.columnheader}.join(', ')}"
    end

    redirect_to :back
  end
  

  def show

    @contacts = @dataset.owners
    @projects = @dataset.projects.uniq
    @freeformats = @dataset.freeformats
    @datacolumns = @dataset.datacolumns

  end

  def download
    @dataset.increment_download_counter
    send_data @dataset.export_to_excel_as_stream, :content_type => "application/xls",
              :filename => "download_#{@dataset.downloads}_#{@dataset.filename}"
  end

  
  # This action provides edit forms for the given context
  def edit
    # Main auth determination happens in AdminBaseController
    @contacts = @dataset.users.select{|p| p.has_role?(:owner, @context)}
    @contact = @contacts.first
    @projects = []
    @contacts.each do |p|
      projects = p.projects
      projects = projects.uniq
      @projects << projects
    end
    @project = @projects.first
  end

  def clean
    if @dataset && params[:datafile]
      @dataset.clean
      @dataset.upload_spreadsheet = Datafile.new(params[:datafile])
      @dataset.save
      redirect_to data_dataset_path(@dataset) and return
    else
      redirect_back_or_default root_url
    end
  end

  def destroy
    @dataset.destroy
  
    flash[:notice] = "Dataset successfully deleted."
    redirect_to data_path
  end


  # ----------------------------------------------------------
  # Freeformat actions - TODO move to own controller
  # ----------------------------------------------------------

  def create_dataset_with_freeformat_file
      freeformat = Freeformat.create!(params[:freeformat])
      @filename = freeformat.file_file_name
      @dataset = Dataset.new
      @dataset.title = @filename
      @dataset.abstract = @filename
      @dataset.filename = @filename
      @dataset.freeformats << freeformat

      unless @dataset.save
        flash[:error] = "#{@dataset.errors.to_a.first.capitalize}"
        redirect_to data_path and return
      end
  end


  def update_dataset_with_only_freeformat_file

    unless @dataset.update_attributes(params[:dataset])
      flash[:error] = "#{@dataset.errors.to_a.first.capitalize}"
      redirect_to data_path and return
    end
    @project_list = Project.order(:shortname)
    render :update_dataset_freeformat_associations
  end

  def save_dataset_freeformat_associations

      @dataset = Dataset.find(params[:dataset][:id])
      @owner = User.find(params[:owner][:owner_id])
      @project = Project.find(params[:project][:project_id])

      @owner.has_role! :owner, @dataset
      @dataset.projects << @project

      render :update_dataset_freeformat_tags

  end
  
  def save_dataset_freeformat_tags
    @dataset.update_attributes(params[:dataset])

    redirect_to dataset_url @dataset
  end

  def update_dataset_freeformat_file
    freeformat = Freeformat.find(params[:freeformat][:id])
    freeformat.file = params[:freeformat][:file]
    if freeformat.save
      redirect_to :controller => :datasets, :action => :show, :id => freeformat.dataset.id
    else
      flash[:error] = "#{freeformat.errors.to_a.first.capitalize}"
      redirect_to :back
    end
  end

  def download_freeformat
    send_file @freeformat.file.path
  end


  private

  def dataset_is_free_for_members
    return true if @dataset.free_for_members  unless @dataset.blank?
    false
  end

  def dataset_is_free_for_public
    return true if @dataset.free_for_public unless @dataset.blank?
    false
  end

  def load_dataset
    @dataset = Dataset.find(params[:id])
  end

  def load_freeformat_dataset
    @freeformat = Freeformat.find(params[:id])
    @dataset = @freeformat.dataset
  end

  def load_dataset_freeformat
    @dataset = Dataset.find(params[:dataset_id])
  end

  def access_denied
    if current_user
      flash[:error] = 'Access denied. You do not have the appropriate rights to perform this operation.'
      redirect_to :back
    else
      flash[:error] = 'Access denied. Try to log in first.'
      session[:return_to] = request.env['HTTP_REFERER']
      redirect_to login_path
    end
  end

end
