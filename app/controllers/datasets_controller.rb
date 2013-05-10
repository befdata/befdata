class DatasetsController < ApplicationController
  helper FreeformatsHelper

  before_filter :load_dataset, :only => [:download, :download_page, :show, :edit, :edit_files, :update, :approve, :approve_predefined,
                                         :update_workbook, :destroy, :regenerate_download,
                                         :approval_quick, :batch_update_columns, :keywords, :download_status, :freeformats_csv]

  before_filter :redirect_if_unimported, :only => [:download, :edit, :approve, :approve_predefined, :destroy,
                                                   :approval_quick, :batch_update_columns, :keywords]

  before_filter :redirect_if_without_workbook, :only => [:download_page, :download, :regenerate_download]

  after_filter :edit_message_datacolumns, :only => [:batch_update_columns, :approve_predefined]

  skip_before_filter :deny_access_to_all

  access_control do
    allow all, :to => [:show, :index, :load_context, :download_excel_template, :importing, :keywords, :download_status]

    actions :edit, :edit_files, :update, :approve, :approve_predefined,
      :approval_quick, :batch_update_columns do
      allow :admin
      allow :data_admin
      allow :owner, :of => :dataset
    end

    actions :update_workbook, :destroy do
      allow :admin
      allow :owner, :of => :dataset
    end

    actions :download, :download_page, :regenerate_download, :freeformats_csv do
      allow :admin, :data_admin
      allow :owner, :proposer, :of => :dataset
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
        @dataset.dataworkbook.members_listed_as_responsible[:found_users].each do |user|
          user.has_role!(:owner, @dataset)
        end
        @unfound_usernames = @dataset.dataworkbook.members_listed_as_responsible[:unfound_usernames]
      end
    else
      flash[:error] = @dataset.errors.full_messages.to_sentence
      flash[:error] << datafile.errors.full_messages.to_sentence if datafile
      redirect_to :back
    end
  end

  def update
    # set owners from the drop-down select box. if no one is specified, current user is used
    users_given_as_provenance = params[:people].blank? ? [current_user] : User.find(params[:people])
    @dataset.owners = users_given_as_provenance

    @dataset.refresh_paperproposal_authors

    if @dataset.update_attributes(params[:dataset]) then
      redirect_to dataset_path, notice: "Sucessfully Saved"
      @dataset.log_edit('Metadata updated')
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

      unless hash[:datagroup].blank?
        changes += 1
        datagroup = Datagroup.find(hash[:datagroup])
        datacolumn.approve_datagroup(datagroup)
      end

      unless hash[:import_data_type].blank?
        changes += 1
        datatype = hash[:import_data_type]
        datacolumn.approve_datatype datatype, current_user
      end
    end
    flash[:notice] = "Successfully approved #{changes} properties."
    redirect_to approve_dataset_url(@dataset)
  end

  def approve_predefined
    @dataset.approve_predefined_columns(current_user)

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
      format.eml do
        render_to_string(params[:separate_category_columns], :template=>"datasets/show.eml")
      end
    end
  end

  def download
    @dataset.log_download(current_user)
    respond_to do |format|
      format.html do
        send_file @dataset.generated_spreadsheet.path, :filename => "#{@dataset.filename}"
      end
      format.csv do
        send_data @dataset.to_csv(params[:separate_category_columns] =~ /true/i), :type => "text/csv",
          :disposition => 'attachment', :filename => "#{@dataset.filename}.csv"
      end
    end
  end

  def regenerate_download
    @dataset.enqueue_to_generate_download(:high)
    redirect_back_or_default dataset_path(@dataset)
  end

  def download_status
    render :text => "Status: <span id = #{@dataset.download_status} >" + @dataset.download_status + "</span>"
  end

  def download_excel_template
    send_file Rails.root.join('files', 'template','befdata_workbook_empty.xls'),
        :filename=>'emtpy_excel_template.xls',
        :disposition => 'attachment'
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
    @workbooks = @dataset.upload_spreadsheets
  end


  def update_workbook
    if !params[:datafile] then
      flash[:error] = "No filename given"
      redirect_to :back and return
    end
    new_datafile = @dataset.upload_spreadsheets.build(params[:datafile])
    if new_datafile.save
      @dataset.delete_imported_research_data
      @dataset.filename = new_datafile.file_file_name
      @dataset.import_status = 'new'
      @dataset.save

      @dataset.log_edit('Dataworkbook updated')
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
    # keywords of dataset
    @dataset_keywords = @dataset.tags
    # keywords of datacolumns
    @datacolumn_keywords = @dataset.datacolumns.includes(:tags)
    # related datasets
    @datasets = @dataset.find_related_datasets
  end

  private

  def generate_freeformats_csv(user)
    CSV.generate do |csv|
      csv << ['Filename', 'URL', 'Description']
      @dataset.freeformats.each do |ff|
        csv << [
            ff.file_file_name,
            view_context.complete_freeformat_url(ff, true).to_s,
            ff.description
        ]
      end
    end
  end

  def load_dataset
    @dataset = Dataset.find(params[:id])
  end

  def trigger_import_if_nessecary
    if @dataset.import_status == 'new'
      @book = Dataworkbook.new(@dataset.upload_spreadsheet)
      @dataset.import_status = 'queued'
      @dataset.save
      @dataset.delay.import_data
    end
  end

  def redirect_if_unimported
    if @dataset.import_status != 'finished' && @dataset.has_research_data?
      redirect_to :action => 'show'
    end
  end

  def redirect_if_without_workbook
    unless @dataset.has_research_data?
      flash[:error] = "There is no workbok for #{@dataset.title}"
      redirect_to @dataset
    end
  end

  def edit_message_datacolumns
    @dataset.log_edit('Datacolumns approved')
  end
end
