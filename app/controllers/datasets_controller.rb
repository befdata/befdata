class DatasetsController < ApplicationController

  before_filter :load_dataset, :only => [:download, :show, :edit, :update, :data, :approve_predefined,
                                         :delete_imported_research_data_and_file, :destroy]

  rescue_from 'Acl9::AccessDenied', :with => :access_denied

  skip_before_filter :deny_access_to_all

  access_control do
    allow all, :to => [:show, :index, :load_context]

    actions :download, :edit, :update, :data, :approve_predefined  do
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

  def new
    @file = Datafile.new
  end

  def create
    @dataset = Dataset.new

    if params[:datafile] then
      datafile = Datafile.new(params[:datafile])
      @dataset.upload_spreadsheet = datafile
      if !datafile.save
        flash[:error] = datafile.errors.full_messages.to_sentence
        redirect_to(:back) and return
      end
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
        redirect_to data_dataset_path(@dataset)
      else
        redirect_to dataset_path
      end
    else
      flash[:error] = @dataset.errors.full_messages.to_sentence
      render :create
    end
  end

  def data
    @book = Dataworkbook.new(@dataset.upload_spreadsheet)

    if @dataset.datacolumns.length == 0
      @book.load_datafile
      return unless @book.columnheaders_unique?
    end

    if @dataset.datacolumns.length == 0
      @book.import_data
      #pid = spawn(@book.import_data, :err=>:out)
      #Process.detach(pid)
      load_dataset #reload
    end
    @predefined_columns = @dataset.predefined_columns
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

  def edit
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
      @dataset.save
      flash[:notice] = "Research data has been replaced."
      redirect_to data_dataset_path(@dataset)
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

end
