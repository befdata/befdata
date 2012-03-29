class DatasetsController < ApplicationController

  before_filter :load_dataset, :only => [:download, :show, :edit, :edit_files, :update, :data, :approve_predefined,
                                         :delete_imported_research_data_and_file, :destroy]

  before_filter :redirect_if_unimported, :only => [:download, :edit, :data, :approve_predefined,
                                                   :destroy]

  rescue_from 'Acl9::AccessDenied', :with => :access_denied

  skip_before_filter :deny_access_to_all

  access_control do
    allow all, :to => [:show, :index, :load_context, :download_excel_template, :importing]

    actions :download, :edit, :edit_files, :update, :data, :approve_predefined  do
      allow :admin
      allow :owner, :of => :dataset
      allow :proposer, :of => :dataset
    end

    actions :delete_imported_research_data_and_file, :destroy do
      allow :admin
      allow :owner, :of => :dataset
    end

    action :download do
      allow logged_in, :if => :dataset_is_free_for_members
      allow logged_in, :if => :dataset_is_free_for_project_of_user
      allow all, :if => :dataset_is_free_for_public
    end

    actions :new, :create do
      allow logged_in
    end
  end


  def create
    # submitting neither title nor datafile
    if !params[:dataset] && !params[:datafile]
      flash[:error] = "No workbook given for upload"
      redirect_to :back and return
    end

    @dataset = Dataset.new

    # Upload option A - from workbook
    if params[:datafile]
      datafile = Datafile.new(params[:datafile])
      @dataset.upload_spreadsheet = datafile
      @dataset.import_status = 'new'
      unless datafile.save
        flash[:error] = datafile.errors.full_messages.to_sentence
        redirect_to(:back) and return
      end
    end

    # Upload option B - empty, only given title
    if params[:dataset] && !params[:datafile]
      @dataset.title = params[:dataset][:title]
    end

    if @dataset.save
      current_user.has_role! :owner, @dataset
      if datafile then
        @dataset.dataworkbook.portal_users_listed_as_responsible.each do |user|
          user.has_role!(:owner, @dataset)
        end
      end
    else
      flash[:error] = @dataset.errors.full_messages.to_sentence
      flash[:error] << datafile.errors.full_messages.to_sentence if datafile
      redirect_to :back
    end
  end

  def update
    users_given_as_provenance = params[:people].blank? ? [] : User.find(params[:people])
    users_with_current_ownership = User.all.select {|u| u.has_role? :owner, @dataset}

    if !users_given_as_provenance.empty? then
      users_with_current_ownership.each do |u|
        u.has_no_role! :owner, @dataset
      end
      users_given_as_provenance.each do |u|
        u.has_role! :owner, @dataset
      end
    # but at least keep current_user if there would be nobody
    elsif users_with_current_ownership.empty? then
      current_user.has_role! :owner, @dataset
    end

    if @dataset.update_attributes(params[:dataset]) then
      if @dataset.has_research_data?
        redirect_to dataset_path
      else
        redirect_to dataset_path
      end
    else
      flash[:error] = @dataset.errors.full_messages.to_sentence
      render :create
    end
  end

  def data
    @predefined_columns = @dataset.predefined_columns
  end

  # to be used by the ajax import status query
  def importing
    @dataset = Dataset.find(params[:id], :select => ['id','import_status'])
    render :text => @dataset.import_status
  end

  def approve_predefined
    @dataset.approve_predefined_columns(current_user)

    if @dataset.columns_with_invalid_values_after_approving_predefined.blank?
      flash[:notice] = "All available columns were successfully approved."
    else
      flash[:error] = "Unfortunately we could not validate entries in the following data columns:
        #{@dataset.columns_with_invalid_values_after_approving_predefined.map{|c| c.columnheader}.join(', ')}"
    end
    redirect_to :back
  end

  def show
    trigger_import_if_nessecary

    @contacts = @dataset.owners
    @projects = @dataset.projects
    @freeformats = @dataset.freeformats :order => :file_file_name
    @datacolumns = @dataset.datacolumns

    respond_to do |format|
      format.html
      format.eml
    end
  end

  def download
    @dataset.increment_download_counter
    send_data @dataset.export_to_excel_as_stream, :content_type => "application/xls",
              :filename => "download_#{@dataset.downloads}_#{@dataset.filename}"
  end

  def download_excel_template
    send_file Rails.root.join('files', 'template','befdata_workbook_empty.xls'),
        :filename=>'emtpy_excel_template.xls',
        :disposition => 'attachment'
  end

  def edit_files
    unless @dataset.finished_import?
      redirect_to(:action => 'show') and return
    end
    @freeformats = @dataset.freeformats :order => :file_file_name
  end


  def delete_imported_research_data_and_file
    if !params[:datafile] then
      flash[:error] = "No filename given"
      redirect_to :back and return
    end
    new_datafile = Datafile.new(params[:datafile])
    if new_datafile.save
      @dataset.delete_imported_research_data_and_file
      @dataset.upload_spreadsheet = new_datafile
      @dataset.filename = new_datafile.file_file_name
      @dataset.import_status = 'new'
      @dataset.save
      flash[:notice] = "Research data has been replaced."
      redirect_to(:action => 'show')
    else
      flash[:error] = new_datafile.errors.full_messages.to_sentence
      redirect_to edit_dataset_path(@dataset)
    end
  end

  def destroy
    @dataset.delete_sheetcells
    @dataset.destroy
    flash[:notice] = "The dataset was successfully deleted."
    redirect_to data_path
  end

  private

  def load_dataset
    @dataset = Dataset.find(params[:id])
  end

  def trigger_import_if_nessecary
    if @dataset.import_status == 'new'
      @book = Dataworkbook.new(@dataset.upload_spreadsheet)
      return unless @book.columnheaders_unique?

      @dataset.import_status = 'enqued'
      @dataset.save
      @dataset.delay.import_data
    end
  end

  def redirect_if_unimported
    if @dataset.import_status != 'finished' && @dataset.has_research_data?
      redirect_to :action => 'show'
    end
  end

end