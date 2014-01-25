class DatasetsController < ApplicationController
  skip_before_filter :deny_access_to_all
  before_filter :load_dataset, :except => [:new, :create, :create_with_datafile, :importing, :index, :download_excel_template]

  before_filter :redirect_if_without_workbook, :only => [:download, :download_page,
                          :approve, :approve_predefined, :batch_update_columns, :approval_quick]
  before_filter :redirect_unless_import_succeed, :only => [:download_page, :download,
                          :approve, :approve_predefined, :approval_quick, :batch_update_columns]
  before_filter :redirect_while_importing, :only => [:edit_files, :update_workbook, :destroy]
  after_filter :edit_message_datacolumns, :only => [:batch_update_columns, :approve_predefined]

  access_control do
    allow all, :to => [:show, :index, :download_excel_template, :importing, :keywords, :download_status]

    actions :edit, :update, :destroy, :edit_files, :update_workbook, :approve, :approve_predefined,
      :approval_quick, :batch_update_columns do
      allow :admin, :data_admin
      allow :owner, :of => :dataset
    end

    actions :download, :download_page, :freeformats_csv do
      allow :admin, :data_admin
      allow :owner, :proposer, :of => :dataset
      allow logged_in, :if => :dataset_is_free_for_members
      allow logged_in, :if => :dataset_is_free_for_project_of_user
      allow all, :if => :dataset_is_free_for_public
    end

    actions :new, :create, :create_with_datafile do
      allow logged_in
    end
  end

  def create # create dataset with only a title
    @dataset = Dataset.new(title: params[:dataset][:title].squish)
    if @dataset.save
      current_user.has_role! :owner, @dataset
    else
      flash[:error] = @dataset.errors.full_messages.to_sentence
      redirect_to :back
    end
  end

  def create_with_datafile
    unless params[:datafile]
      flash[:error] = "No data file given for upload"
      redirect_back_or_default root_url and return
    end

    datafile = Datafile.new(params[:datafile])
    unless datafile.save
      flash[:error] = datafile.errors.full_messages.to_sentence
      redirect_back_or_default root_url and return
    end

    attributes = datafile.general_metadata_hash
    attributes.merge!(title: params[:title].squish) if params[:title]
    @dataset = Dataset.new(attributes)
    if @dataset.save
      @dataset.add_datafile(datafile)
      @dataset.load_projects_and_authors_from_current_datafile
      current_user.has_role! :owner, @dataset
      @unfound_usernames = datafile.authors_list[:unfound_usernames]
      render :action => :create
    else
      datafile.destroy
      flash[:error] = @dataset.errors.full_messages.to_sentence
      redirect_back_or_default root_url
    end
  end

  def update
    if @dataset.update_attributes(params[:dataset])
      @dataset.refresh_paperproposal_authors if params[:dataset][:owner_ids].present?
      # TODO: should not refresh all authors of the pp
      @dataset.log_edit('Metadata updated')
      redirect_to dataset_path, notice: "Sucessfully Saved"
    else
      last_request = request.env["HTTP_REFERER"]
      render :action => (last_request == edit_dataset_url(@dataset) ? :edit : :create)
    end
  end

  # to be used by the ajax import status query
  def importing
    @dataset = Dataset.find(params[:id], :select => ['id','import_status'])
    render :text => @dataset.import_status
  end

  def approve
    @predefined_columns = @dataset.predefined_columns.collect{|c| c.id}
    render :layout => 'approval'
  end

  def approval_quick
    @datagroups = Datagroup.order(:title)
    @datatypes = Datatypehelper.known
    render :layout => 'approval'
  end

  def batch_update_columns
    datacolumns = params[:datacolumn]
    changes = 0
    datacolumns.each do |hash|
      datacolumn = Datacolumn.find hash[:id]
      unless datacolumn.dataset == @dataset
        flash[:error] = "Updated datacolumns must be part of the dataset!"
        redirect_to approve_dataset_url(@dataset) and return
      end

      if hash[:datagroup].present?
        datagroup = Datagroup.find(hash[:datagroup])
        datacolumn.approve_datagroup(datagroup)
        changes += 1
      end

      if datacolumn.datagroup_approved && hash[:import_data_type].present?
        datatype = hash[:import_data_type]
        datacolumn.approve_datatype datatype, current_user
        changes += 1
      end
    end
    flash[:notice] = "Successfully approved #{changes} properties."
    redirect_to approve_dataset_url(@dataset)
  end

  def approve_predefined
    @dataset.approve_predefined_columns

    if @dataset.columns_with_invalid_values_after_approving_predefined.blank?
      flash[:notice] = "All available columns were successfully approved."
    else
      still_unapproved_columns = @dataset.columns_with_invalid_values_after_approving_predefined
      flash[:error] = "Unfortunately we could not automatically validate entries in the following data columns:
        #{still_unapproved_columns.map{|c| c.columnheader}.join(', ')}"
      flash[:non_auto_approved] = still_unapproved_columns.map{|c| c.id}
    end
    redirect_to :back
  end

  def show
    trigger_import_if_nessecary

    @contacts = @dataset.owners
    @projects = @dataset.projects
    @freeformats = @dataset.freeformats :order => :file_file_name
    @datacolumns = @dataset.datacolumns.includes(:datagroup, :tags)
    @tags = @dataset.all_tags

    respond_to do |format|
      format.html
      format.xml
      format.eml
    end
  end

  def index
    datasets = Dataset.select("id, title").order(:id)

    respond_to do |format|
      format.json { render :json => datasets }
      format.xml { render :xml => datasets }
    end
  end

  def download_page
    @exported_excel = @dataset.exported_excel || @dataset.create_exported_excel
    @exported_csv = @dataset.exported_csv || @dataset.create_exported_csv
    @exported_scc_csv = @dataset.exported_scc_csv || @dataset.create_exported_scc_csv
    @freeformats = @dataset.freeformats
  end

  def download_status
    respond_to do |format|
      format.json {
        result = {}

        if @dataset.has_research_data?
          if @dataset.finished_import?
            @dataset.exported_files.each {|ef| result[ef.format] = ef.status }
          else
            result[:error] = 'Importing of the dataset is not finished yet.'
          end
        else
          result[:error] = 'The requested dataset has no data'
        end
        render :json => result
      }
    end
  end

  def download
    @dataset.log_download(current_user)
    respond_to do |format|
      format.html do
        send_file_if_exists @dataset.exported_excel, :filename => "#{@dataset.filename}.xls"
      end
      format.csv do
        if params[:separate_category_columns] =~ /true/i
          send_file_if_exists @dataset.exported_scc_csv, :filename => "#{@dataset.filename}-scc.csv", :disposition => 'attachment'
        else
          send_file_if_exists @dataset.exported_csv, :filename => "#{@dataset.filename}.csv", :disposition => 'attachment'
        end
      end
    end
  end

  def freeformats_csv
    filename = "dataset-#{@dataset.id.to_s}-files" + (current_user ? "-for-#{current_user.login}" : '') + '.csv'
    send_data generate_freeformats_csv(true), :type => 'text/csv',
              :disposition => 'attachment', :filename => filename
  end

  def edit_files
    unless @dataset.import_status.nil? || @dataset.import_status.starts_with?('finished','error')
      redirect_to(:action => 'show') and return
    end
    @freeformats = @dataset.freeformats :order => :file_file_name
    @datafiles = @dataset.datafiles
  end


  def update_workbook
    unless params[:datafile]
      flash[:error] = "No filename given"
      redirect_to :back and return
    end
    new_datafile = Datafile.new(params[:datafile])
    if new_datafile.save
      @dataset.delete_imported_research_data
      @dataset.add_datafile(new_datafile)
      @dataset.log_edit('Workbook updated')
      flash[:notice] = "Research data has been replaced."
      redirect_to(:action => 'show')
    else
      flash[:error] = new_datafile.errors.full_messages.to_sentence
      redirect_to :back
    end
  end

  def destroy
    if @dataset.destroy
      flash[:notice] = "The dataset was successfully deleted."
      redirect_to data_path
    else
      flash[:error] = @dataset.errors.full_messages.to_sentence
      redirect_to :back
    end
  end

  def keywords
    @dataset_keywords = @dataset.tags
    @datacolumns = @dataset.datacolumns.includes(:tags)
    @related_datasets = @dataset.find_related_datasets
  end

private

  def generate_freeformats_csv(user)
    CSV.generate do |csv|
      csv << ['Filename', 'URL', 'Description']
      @dataset.freeformats.each do |ff|
        csv << [
            ff.file_file_name, download_freeformat_url(ff, user_credentials: current_user.try(:single_access_token)), ff.description ]
      end
    end
  end

  def load_dataset
    @dataset = Dataset.find(params[:id])
  end

  def trigger_import_if_nessecary
    if @dataset.import_status.eql? 'new'
      @dataset.update_attribute(:import_status, 'queued')
      @dataset.delay.import_data
    end
  end

  def redirect_if_without_workbook
    unless @dataset.has_research_data?
      flash[:error] = "The operation requires the dataset to have a workbook, but it doesn't."
      redirect_to :action => 'show' and return
    end
  end

  def redirect_unless_import_succeed
    unless @dataset.import_status == 'finished'
      flash[:error] = "The dataset hasn't been successfully imported!"
      redirect_to :action => 'show' and return
    end
  end

  def redirect_while_importing
    if @dataset.being_imported?
      flash[:error] = "Please wait till the importing finishes"
      redirect_to :action => 'show' and return
    end
  end

  def edit_message_datacolumns
    @dataset.log_edit('Datacolumns approved')
  end

  def send_file_if_exists(file, options = {})
    if file && file.path && File.file?(file.path)
      send_file file.path, options
    else
      flash[:error] = "The file is not found on the server. Maybe it's being generated, Please wait till it's finished."
      redirect_back_or_default download_page_dataset_path(@dataset)
    end
  end
end
