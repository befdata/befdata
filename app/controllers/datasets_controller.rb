class DatasetsController < ApplicationController

  before_filter :load_dataset, :only => [:download, :show, :edit, :data, :clean, :destroy]

  before_filter :load_freeformat_dataset, :only => [:download_freeformat]

  before_filter :load_dataset_freeformat, :only => [:update_dataset_freeformat_associations]

  rescue_from 'Acl9::AccessDenied', :with => :access_denied

  skip_before_filter :deny_access_to_all
  access_control do
    allow all, :to => [:show, :index, :load_context]

    # proponents should not be able to alter aspects of datasets they do not own
    # update freeformat associations: dataset through params[:dataset_id]
    # download freeformat: no dataset, freeformat through params[:id]
    # save freeformat associations: dataset through params[:dataset][:id]
    # save dataset freeformat association: dataset through params[:dataset][:id]
    actions :download, :edit, :data, :update_freeformat_associations, :save_freeformat_associations,
    :download_freeformat, :save_dataset_freeformat_associations do
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

    # for the first upload of the file, before owners are associated, logged in users have the right
    # to update freeformat associations
    actions :create, :upload, :upload_freeformat, :upload_dataset_freeformat, :create_freeformat,
    :create_dataset_freeformat, :update_dataset_freeformat_associations do
      allow logged_in
    end
  end

  def create
    datafile = Datafile.new(params[:datafile])

    unless datafile.save
      flash[:error] = "#{datafile.errors.to_a.first.capitalize}"
      redirect_to :back
    end

    begin
      book = Dataworkbook.new(datafile)
      # after closing, the file can be destroyed if necessary, the
      # information stays in the book object

      # Start with the first sheet; if the page is reloaded, there
      # may already be a context to this datafile
      if datafile.dataset.blank?
        @dataset = Dataset.new
        @dataset.upload_spreadsheet = datafile

        # gather all the cell values that can just be copied into
        # the new context
        @dataset.update_attributes(book.general_metadata_hash)

        # Calculate the start and end dates of field research
        @dataset.datemin = book.datemin
        @dataset.datemax = book.datemax
        book.give_owner_rights_to_members_listed_as_responsible(@dataset)
        
      else # there already is context information for this file
        @dataset = datafile.dataset
      end

      # Project Tag list
      @dataset.projecttag_list = book.tag_list unless book.tag_list.blank?

      # the uploader should be owner, too
      current_user.has_role! :owner, @dataset

      @dataset.save

      # Render the page that presents the general metadata for a
      # data set, for user interaction
      @step = 1
      @people_list = User.find(:all, :order => :lastname)
    rescue Ole::Storage::FormatError
      # Uploaded file was no valid Excel file
      redirect_to data_path and return
    end
  end

  # This action provides edit forms for the given context
  def edit
    # Main auth determination happens in AdminBaseController
    @step = 0
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

  def show

    @contacts = @dataset.owners
    @projects = @dataset.projects.uniq
    @freeformats = @dataset.freeformats
    @datacolumns = @dataset.datacolumns

    # The determination of Vip or Vop status only makes sense if the
    # current user is logged in
    #ToDo Was macht das?
    # @submethod_list_user = []
    #    if logged_in?
    #      # This loop checks the Vip/Vop-status for every PersonRole, the
    #      # current user plays.  If any status is found, the view renders
    #      # a appropriate download link.
    #      @vip = false
    #      @vop = false
    #
    #      proles = @current_user.person_roles
    #      proles.each do |r|
    #        @vip = true if @context.vips.include?(r)
    #        @vop = true if @context.vops.include?(r)
    #      end
    #
    #      # list of submethods of this user
    #      tmp = proles.collect{|pr| pr.measmeths_personroles}.flatten.uniq
    #      @submethod_list_user = tmp.collect{|mp| mp.measurements_methodstep}.flatten.uniq
    #    else # not logged_in
    #      @submethod_list_user = []
    #
    #    end # if logged_in?

  end


  def data
    @book = Dataworkbook.new(@dataset.upload_spreadsheet)

    return unless @book.columnheaders_unique?
  
    if @dataset.datacolumns.length == 0
      @just_uploaded = true
      @book.import_data(@dataset.id, current_user)
      load_dataset #reload
    end

  end
  
  # Downloading one free format file from within the "show" view
  def download_freeformat
    send_file @freeformat.file.path
  end

  # This action assembles a requested context, or a part of it, at
  # request time. (!! This could be moved to the model with all the
  # private actions, they can then also be used in the
  # ImportController)
  def download

    #     @data_sheet = DataSheet.new
    #     book = DataSheet.new
    report = StringIO.new
    Spreadsheet.client_encoding = 'UTF-8'
    book = Spreadsheet::Workbook.new

    # Define the formats for the spreadsheet
    formats = {}
    formats[:dataformat] = Spreadsheet::Format.new :size => 11, :horizontal_align => :left, :italic => true
    formats[:metaformat] = Spreadsheet::Format.new :size => 11, :horizontal_align => :left, :color => 'brown'
    # Write the metadata sheet
    create_metasheet(book, @dataset, formats)
    logger.debug "metasheet created"

    create_methodsheet(book, @dataset, formats)
    logger.debug "methodsheet created"
    create_peoplesheet(book, @dataset, formats)
    logger.debug "peoplesheet created"
    create_categorysheet(book, @dataset, formats)
    logger.debug "categorysheet created"
    # if data sheet is too large, it has to be saved
    # as .csv file
    create_datasheet(book, @dataset, formats)
    # this should be basename and then the number of the download
    filename = "download#{@dataset.downloads}_#{@dataset.filename}"

    # Write the book to the stream and send it back to the browser
    book.write(report)
    send_data report.string, :content_type => "application/xls", :filename => filename

    # Add 1 to the download counter
    @dataset.downloads = (@dataset.downloads || 0) + 1
    @dataset.save
  end


  def upload_dataset_freeformat
    freeformat_id = params[:freeformat_id]
    if !freeformat_id.blank?
      freeformat = Freeformat.find(params[:freeformat_id])
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
    else
      redirect_to data_path and return
    end
  end


  def create_dataset_freeformat
    @dataset = Dataset.find(params[:dataset][:id])

    unless @dataset.update_attributes(params[:dataset])
      flash[:error] = "#{@dataset.errors.to_a.first.capitalize}"
      redirect_to data_path and return
    else
      redirect_to url_for(:controller => :datasets,
      :action => :update_dataset_freeformat_associations,
      :dataset_id => @dataset.id) and return
    end
  end


  def update_dataset_freeformat_associations

    begin
      # @dataset = Dataset.find(params[:dataset_id])  # before filter
      @people_list = User.find(:all, :order => :lastname)
      @project_list = Project.find(:all, :order => :shortname)

    rescue ActiveRecord::RecordNotFound
      # No context with this id exists
      redirect_to data_path and return
    end

  end


  def save_dataset_freeformat_associations
    begin
      @dataset = Dataset.find(params[:dataset][:id])
      @owner = User.find(params[:owner][:owner_id])
      @project = Project.find(params[:project][:project_id])

      @owner.has_role! :owner, @dataset
      @dataset.projects << @project

      redirect_to url_for(:controller => :imports,
      :action => :dataset_freeformat_overview,
      :dataset_id => @dataset.id) and return

    rescue ActiveRecord::RecordNotFound
      # No context with this id exists
      redirect_to data_path and return
    end
  end

  def upload
    redirect_to data_path and return unless %w[1 5].include?(params[:step])

    @dataset = Dataset.find(params[:dataset_id])
    redirect_to data_path and return if @dataset.blank? # No dataset found

    case params[:step]
    when '1'
      # At this point, the parameter "filename" is given; there has
      # already an upload been done, the context for which "upload"
      # is called is already existing.  Because of this, the upload
      # of a file is leaped over.  We are at step 1.

      if !params[:people].blank? then
        users = User.find(params[:people])
        # assigning provenance information: linking people to the data set
        users.each do |pr|
          pr.has_role! :owner, @dataset
        end
      else
        # add at least the uploader
        current_user.has_role! :owner, @dataset
      end

      
      @dataset.update_attributes( :title => params[:title],
      :abstract => params[:abstract],
      :comment => params[:comment],
      :usagerights => params[:usagerights],
      :published => params[:published],
      :spatialextent => params[:spatialextent],
      :datemin => DateTime.civil(params[:date][:"min(1i)"].to_i, params[:date][:"min(2i)"].to_i, params[:date][:"min(3i)"].to_i, params[:date][:"min(4i)"].to_i, params[:date][:"min(5i)"].to_i),
      :datemax => DateTime.civil(params[:date][:"max(1i)"].to_i, params[:date][:"max(2i)"].to_i, params[:date][:"max(3i)"].to_i, params[:date][:"max(4i)"].to_i, params[:date][:"max(5i)"].to_i),
      :temporalextent => params[:temporalextent],
      :taxonomicextent => params[:taxonomicextent],
      :design => params[:design],
      :dataanalysis => params[:dataanalysis],
      :circumstances => params[:circumstances] )

      # Finally, set the new step, so that the evaluation process
      # moves forward
      redirect_to data_dataset_path(@dataset) and return
    when '5'
      @step = 5

      # Upoading and evaluation finished
      @dataset.finished = params[:finished]
      @dataset.save

      # If the dataset is finished, show it
      redirect_to url_for :controller => :datasets, :action => :show, :id => @dataset.id and return if @dataset.finished
    end
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

  def destroy
    @dataset.destroy
  
    flash[:notice] = "Dataset successfully deleted."
    redirect_to data_path
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

  # Creates the first sheet of a context file, the one with the
  # metadata.
  def create_metasheet (book, context, formats)
    # This action canot be called externally.
    sheet = book.create_worksheet :name => 'General Metadata'

    sheet.column(0).width = 80

    [0, 2, 5, 8].each{|n| sheet.row(n).set_format(0, formats[:metaformat])}
    sheet[0,0] = t('metadata.head')
    sheet[2,0] = t('metadata.title')
    sheet.row(3).set_format(0, formats[:dataformat])
    sheet[3,0] = context.title ||= ""

    sheet[5,0] = t('metadata.abstract')
    sheet[6,0] = context.abstract ||= ""
    sheet.row(6).set_format(0, formats[:dataformat])

    sheet[8,0] = t('metadata.comments')
    sheet[9,0] = context.comment ||= ""
    sheet.row(9).set_format(0, formats[:dataformat])

    (11..18).each{|n| sheet.row(n).set_format(0, formats[:metaformat])}
    sheet[11,0] = t('metadata.project')
    sheet[11,1] = context.projecttag_list

    sheet[13,0] = t('metadata.people')
    sheet[14,0] = t('metadata.givenname')
    sheet[15,0] = t('metadata.surname')
    sheet[16,0] = t('metadata.email')

    c_owners = context.users.select{|p| p.has_role?(:owner, context)}
    unless c_owners.blank?
      i = 1
      c_owners.each do |cpr|
        sheet.column(i).default_format = formats[:dataformat]
        sheet.column(1).width = 30

        sheet[14,i] = cpr.firstname ||= ""
        sheet[15,i] = cpr.lastname ||= ""
        # sheet[14,i] = cprpr.project.shortname ||= ""
        # if cprpr.institution.nil?
        #   sheet[15,i] = ""
        #   sheet[16,i] = ""
        #   sheet[17,i] = ""
        # else
        #   sheet[15,i] = cprpr.institution.name
        #   sheet[16,i] = cprpr.institution.city
        sheet[16,i] = cpr.email
        # end
        # sheet[18,i] = cprpr.role.name ||= ""
        i += 1
      end
    end

    [21, 23, 26, 27, 30, 31, 33, 35, 38, 41, 44, 47].each{|n| sheet.row(n).set_format(0, formats[:metaformat])}
    sheet[21,0] = t('metadata.usagerights')
    sheet[22,0] = context.usagerights ||= ""
    sheet.row(22).set_format(0, formats[:dataformat])

    sheet[23,0] = t('metadata.published')
    sheet[24,0] = context.published ||= ""
    sheet.row(24).set_format(0, formats[:dataformat])

    sheet[26,0] = t('metadata.methods')
    sheet[27,0] = t('metadata.spatialextent')
    sheet[28,0] = context.spatialextent ||= ""
    sheet.row(28).set_format(0, formats[:dataformat])

    sheet[30,0] = t('metadata.temporalextent')
    sheet[31,0] = t('metadata.datemin')
    sheet[32,0] = context.datemin.to_date.to_s ||= ""
    sheet.row(32).set_format(0, formats[:dataformat])

    sheet[33,0] = t('metadata.datemax')
    sheet[34,0] = context.datemax.to_date.to_s ||= ""
    sheet.row(34).set_format(0, formats[:dataformat])

    sheet[35,0] = t('metadata.datedescription')
    sheet[36,0] = context.temporalextent ||= ""
    sheet.row(36).set_format(0, formats[:dataformat])

    sheet[38,0] = t('metadata.taxonomicextent')
    sheet[39,0] = context.taxonomicextent ||= ""
    sheet.row(39).set_format(0, formats[:dataformat])

    sheet[41,0] = t('metadata.design')
    sheet[42,0] = context.design ||= ""
    sheet.row(42).set_format(0, formats[:dataformat])

    sheet[44,0] = t('metadata.dataanalysis')
    sheet[45,0] = context.dataanalysis ||= ""
    sheet.row(45).set_format(0, formats[:dataformat])

    sheet[47,0] = t('metadata.circumstances')
    sheet[48,0] = context.circumstances ||= ""
    sheet.row(48).set_format(0, formats[:dataformat])

    return nil
  end

  # Creates the second sheet of a context file, the one with the
  # method descriptions.  If no methods are given, all methods of the
  # context will be used.
  def create_methodsheet (book, dataset, formats, methods = nil)
    # This action canot be called externally.

    #Create the sheet and fill in the headers
    sheet = book.create_worksheet :name => 'Column description'

    sheet.row(0).default_format = formats[:metaformat]
    sheet.row(0).height = 120

    sheet[0,0] = "Column header"
    sheet[0,1] = "Definition"
    sheet[0,2] = "Unit of measurement"
    sheet[0,3] = "Missing value code"
    sheet[0,4] = "Coma separated keywords"
    sheet[0,5] = "Method step title"
    sheet[0,6] = "Method step description"
    sheet[0,7] = "Method instrumentation"
    sheet[0,8] = "Identification source"
    sheet[0,9] = "Number type"
    sheet[0,10] = "Relevant time scale"
    sheet[0,11] = "Unit timescale"

    if methods
      # If methods are given, use the given methods.
      mms = methods
    else
      # If no methods are given, use all methods of the context.
      mms = Datacolumn.find(:all, :conditions => ["dataset_id = ?", dataset.id], :order => "columnnr ASC")
    end

    row = 0
    mms.each do |datacolumn|
      if methods
        # If only some methods are rendered, each MeasurementsMethodstep is rendered from the beginning of the page
        row += 1
      else
        # Otherwise, if all methods are used, we can take the original columnnr
        row = datacolumn.columnnr
      end

      sheet.row(row).default_format = formats[:dataformat]
      sheet[row,0] = datacolumn.columnheader if datacolumn.columnheader
      sheet[row,1] = datacolumn.definition if datacolumn.definition
      sheet[row,2] = datacolumn.unit if datacolumn.unit
      sheet[row,3] = datacolumn.missingcode if datacolumn.missingcode
      # tag list into comments
      comment = datacolumn.tag_list.join(", ")
      sheet[row,4] = comment if comment

      sheet[row,5] = datacolumn.datagroup.title if datacolumn.datagroup.title
      sheet[row,6] = datacolumn.datagroup.description if datacolumn.datagroup.description
      sheet[row,7] = datacolumn.datagroup.instrumentation if datacolumn.datagroup.instrumentation
      sheet[row,8] = datacolumn.datagroup.informationsource if datacolumn.datagroup.informationsource
      sheet[row,9] = datacolumn.datagroup.methodvaluetype if datacolumn.datagroup.methodvaluetype
      sheet[row,10] = datacolumn.datagroup.timelatency if datacolumn.datagroup.timelatency
      sheet[row,11] = datacolumn.datagroup.timelatencyunit if datacolumn.datagroup.timelatencyunit
    end
  end

  # Creates the third sheet of a context file, the one with the people
  # involved.  If no Method are given, all people of the context will
  # be listed.
  def create_peoplesheet (book, dataset, formats, methods = nil)
    # This action canot be called externally.

    sheet = book.create_worksheet :name => 'Members involved'

    sheet.row(0).default_format = formats[:metaformat]
    sheet.row(0).height = 120

    sheet[0,0] = "Column header"
    sheet[0,1] = "Given name of person mainly associated to the data in the column"
    sheet[0,2] = "Surname of person mainly associated to the data in the column"
    sheet[0,3] = "Project code"
    sheet[0,4] = "Role"

    if methods
      # If methods are given, use the given methods.
      mms = methods
    else
      # If no methods are given, use all methods of the context.
      mms = Datacolumn.find(:all, :conditions => ["dataset_id = ?", dataset.id], :order => "columnnr ASC")
    end

    row = 1
    mms.each do |step|
      step.users.each do |pr|
        # Each PersonRole is rendered in its own row, starting at the beginning of the page

        sheet.row(row).default_format = formats[:dataformat]
        sheet[row,0] = step.columnheader if step.columnheader
        sheet[row,1] = pr.firstname if pr.firstname
        sheet[row,2] = pr.lastname if pr.lastname
        # sheet[row,3] = pr.person_role.project.shortname if pr.person_role.project.shortname
        # sheet[row,4] = pr.person_role.role.name if pr.person_role.role.name

        row += 1
      end
    end

  end

  # Creates the fourth sheet of a context file, the one that contains
  # the categoric descriptions.  If no Columns  are given, all
  # appropriate categories of the context will be listed.
  # Note: Columns were earlier called methods
  def create_categorysheet(book, dataset, formats, columns = nil)
    # This action canot be called externally.

    sheet = book.create_worksheet :name => 'column categories'

    sheet.row(0).default_format = formats[:metaformat]
    sheet.row(0).height = 120
    sheet[0,0] = "Column header"
    sheet[0,1] = "Category short"
    sheet[0,2] = "Category long"
    sheet[0,3] = "Category description"

    if columns
      cols = columns
    else
      cols = Datacolumn.find(:all, :conditions => ["dataset_id = ?", dataset.id], :order => "columnnr ASC")
    end

    category_cols = cols.select{|c| (c.sheetcells.first != nil) && (c.sheetcells.first.datatype.is_category?) && (c.datatype_approved)}.uniq

    row = 1
    processed_categories = []
    
    category_cols.each do |category_col|
      category_col.sheetcells.sort{|a,b| a.category.short <=> b.category.short}.each do |sheetcell|
        unless processed_categories.include?(sheetcell.category.long)
          sheet.row(row).default_format = formats[:dataformat]
          sheet[row,0] = category_col.columnheader
          sheet[row,1] = sheetcell.category.short
          sheet[row,2] = sheetcell.category.long
          sheet[row,3] = sheetcell.category.description

          processed_categories << sheetcell.category.long
          row += 1
        end
      end
    end
  end

  # Creates the last sheet of a context file, the one that contains the raw data.
  # If no Method are given, all people of the context will be listed.
  def create_datasheet (book, dataset, formats, columns = nil)
    # This action canot be called externally.

    sheet = book.create_worksheet :name => 'Raw data'

    if columns
      datacols = columns
    else
      datacols = Datacolumn.find(:all, :conditions => ["dataset_id = ?", dataset.id], :order => "columnnr ASC").uniq
    end

    column = 0
    datacols.each do |datacolumn|
      if columns
        # If only some methods are rendered, each
        # MeasurementsMethodstep is rendered from the beginning of the
        # page
        column += 1
      else
        # Otherwise, if all methods are used, we can take the original columnnr
        column = datacolumn.columnnr
      end

      # Columnheader comes first
      sheet[0,column-1] = datacolumn.columnheader if datacolumn.columnheader

      if datacolumn.datatype_approved then
        datacolumn.sheetcells.each do |sheetcell|
          if sheetcell.datatype.is_category?
            value = sheetcell.category.short
          elsif sheetcell.datatype.to_s.match /^date/
            value = sheetcell.accepted_value.to_date.to_s
          else
            value = sheetcell.accepted_value
          end
          sheet[sheetcell.observation.rownr-1,column-1] = value if value
        end
      end
    end
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
