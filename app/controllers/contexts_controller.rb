# This file handles all incoming calls for data sets.
require 'spreadsheet'

# The ContextController imports the general metadata of a dataset.  It
# then is redirected to the ImportController for the data columns (see
# MeasurementsMethodstep).
class ContextsController < ApplicationController

  before_filter :require_user, :only => [:edit, :download]
  before_filter :load_context, :only => [:download, :show, :edit]


  access_control do

  allow all, :to => [:show, :index, :load_context]
  
  action :download, :edit do
    allow :admin
    allow :owner, :of => :context
    allow :proposer, :of => :context
  end

  action :upload do
    allow logged_in
  end

  end

  # There is no index of Context. Instead, the Data index is displayed.  
  def index
    redirect_to data_path
  end

  # This action handles the whole process of uploading a context file
  # and evaluating its content
  def upload
    if !params[:filevalue_id].blank?
      # When coming from the upload page, a file parameter must be
      # set.  This means, that there has not been any context yet
      # made with this file.
      
      filevalue = Filevalue.find(params[:filevalue_id])
      begin
          
        filepath = filevalue.file.path
        book = Spreadsheet.open filepath
        # after closing, the file can be destroyed if necessary, the
        # information stays in the book object
        book.io.close

        # Start with the first sheet; if the page is reloaded, there
        # may already be a context to this filevalue
        if filevalue.context.blank?
          @context = Context.new
          @context.upload_spreadsheet = filevalue
          
          # gather all the cell values that can just be copied into
          # the new context
          filename = filevalue.file_file_name
          simple_hash = gather_simple_general_metadata(filename, book)
          @context.update_attributes(simple_hash)
          
   
          def parse_date_txt(date_text, day_month_txt)
            begin
              if integer?(date_text)
                date_text = date_text.to_i.to_s
                date_text = day_month_txt + date_text if date_text.length == 4
              end
              date_tmp = DateTime.parse(date_text)
            rescue ArgumentError
              date_tmp = DateTime.parse(Date.today.to_s)
            end
            return(date_tmp)
          end
    
          logger.debug "-- data conversion --"
          datemin = Array(book.worksheet(0).column(0))[32].to_s
          logger.debug "-- datemin #{datemin} --"
          day_month = "1/1/"
          @context.datemin = parse_date_txt(datemin, day_month)
          datemax = Array(book.worksheet(0).column(0))[34].to_s
          logger.debug "-- datemax #{datemax} --"
          day_month = "12/31/"
          @context.datemax = parse_date_txt(datemax, day_month)

   
   
          @context.save
          logger.debug "---------- after saving the new context -------"
          logger.debug @context.valid?
          logger.debug @context.errors.inspect
   
   
          # Gather the people
          # Determine number of people
          cols = Array(book.worksheet(0).row(14)).length
          ppl = cols - 1 # The first column contains only meta data
          logger.debug "------------ ppl.inspect  ---------" 
          logger.debug ppl.inspect
   
#          # The current user is automatically added to the user array
#          logger.debug "---------- after saving the new context -------"
#          people = [@current_user]
          people = []
          
          ppl.times do |i| # starts at 0
            person = Array(book.worksheet(0).column(i+1))[14..15]
            logger.debug "------------ person.inspect  ---------" 
            logger.debug person.inspect
            # Look for the givenName in both name fields
            people += Person.find_all_by_firstname(person[0])
            # people += Person.find_all_by_lastname(person[0])
            
            # Look for the surName in both name fields
            # people += Person.find_all_by_firstname(person[1])
            people += Person.find_all_by_lastname(person[1])
            
            # Additionally, do a fuzzy search on both name values
            # people += Person.fuzzy_find(person[0]) # givenName
            # people += Person.fuzzy_find(person[1]) # surName
            
            people = people.uniq # Eliminate the doubled entries
          end
            
   
          # Add all found roles to the context. Evaluation of
          # correctness will be step 2
          people.each do |pr|
            pr.has_role! :owner, @context
          end

        else # there already is context information for this file
          @context = filevalue.context
        end

        # Project Tag list
        proj_tag_list = Array(book.worksheet(0).column(1))[11]
        @context.projecttag_list = proj_tag_list
        @context.save

        # Render the page that presents the general metadata for a
        # data set, for user interaction
        # (view/contexts/upload.html.erb)
        @step = 1
        @people_list = Person.find(:all, :order => :lastname)
      rescue Ole::Storage::FormatError
        # Uploaded file was no valid Excel file
        redirect_to data_path and return
      end

    elsif params[:step] == '1' 
      # At this point, the parameter "filename" is given; there has
      # already an upload been done, the context for which "upload"
      # is called is already existing.  Because of this, the upload
      # of a file is leaped over.  We are at step 1.
      @context = Context.find(params[:id])
      unless @context.blank?

        people = Person.find(params[:people])

        # assigning provenance information: linking people to the data
        # set
        people.each do |pr|
          pr.has_role! :owner, @context
        end

        @context.update_attributes( :title => params[:title],
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
        redirect_to url_for(:controller => :import, 
                            :action => :raw_data_overview, 
                            :context_id => @context.id) and return
        
      else
        # No context found
        redirect_to data_path and return
      end
    elsif params[:step] == '5'
      @step = 5
      logger.debug " entering step 5 "

      @context = Context.find(params[:context_id])
      logger.debug " loading context "
      logger.debug @context.inspect

      unless @context.blank?
        # Upoading and evaluation finished
        logger.debug "Upoading and evaluation finished, showing params[:finished]"
        logger.info params[:finished]
        @context.finished = params[:finished]
        @context.save


        # If the context is finished, show it
        if @context.finished == true
          logger.debug "After all, rebuild the search index"
          # After all, rebuild the search index
          begin
            Context.rebuild_index
            logger.debug "rebuilding done"
          rescue
            logger.debug "rebuilding did not work"
          end

          redirect_to url_for :controller => :contexts, 
                              :action => :show, 
                              :id => @context.id and return
        else
          logger.debug "context not finished"
          logger.debug [@context.id, @context.title].to_s
        end
      else
        # No context found
        redirect_to data_path and return
      end
    else
      # Neither file parameter nor step parameter. Redirect to the
      # upload page.
      redirect_to data_path and return
    end
#    else
#      # Not logged in, redirect to login form
#      session[:return_to] = request.request_uri
#      redirect_to login_path and return
#    end
  end


  # The general metadata sheet contains information about the data set
  # as a whole.  The gather_simple_general_metadata method gathers the
  # contents of the text cells within this sheet.  Dates as well as
  # people are collected with other methods (!!
  # read_date_from_workbook, assort_people_to_general_metadata).
  def gather_simple_general_metadata(filename, book)
    simple_metadata = Hash.new
    simple_metadata[:filename] = filename
    simple_metadata[:downloads] = 0
    simple_metadata[:finished] = false
    general_sheet =  Array(book.worksheet(0).column(0))
    simple_metadata[:title] = general_sheet[3]
    simple_metadata[:abstract] = general_sheet[6] 
    simple_metadata[:comment] = general_sheet[9] 
    simple_metadata[:usagerights] = general_sheet[22]
    simple_metadata[:published] = general_sheet[24]
    simple_metadata[:spatialextent] = general_sheet[28]
    simple_metadata[:temporalextent] = general_sheet[36]
    simple_metadata[:taxonomicextent] = general_sheet[39]
    simple_metadata[:design] = general_sheet[42]
    simple_metadata[:dataanalysis] = general_sheet[45]
    simple_metadata[:circumstances] = general_sheet[48]
    return simple_metadata
  end



  # This action provides edit forms for the given context
  def edit
    # Main auth determination happens in AdminBaseController    
  end

  # This action provides the details for the given context
  def show
    begin
      @context = Context.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      # No context with this id exists
      redirect_to data_path and return
    end

    # Assemble context owners
    @contacts = @context.people.select{|p| p.has_role?(:owner, @context)}

    @projects = []
    @contacts.each do |p|
      projects = p.projects
      projects = projects.uniq
      @projects << projects
    end
    @projects = @projects.flatten.compact.uniq
    
    tmp = MeasurementsMethodstep.find(:all, 
                                      :conditions => [ "context_id = ?", params[:id] ],
                                      :order => 'columnnr ASC')
    @header = tmp.map{|d| d.columnheader }.uniq

    @measmeths = {}
    @measurements = {}
    @methodtitles = {}

    @header.each do |h|
      mm = tmp.select{|mm| mm.columnheader == h}.first
      @measmeths[h] = mm
      @measurements[h] = Measurement.find(:all, 
                                          :conditions => [ "measurements_methodstep_id = ?", mm.id ])
      @methodtitles[h] = tmp.select{|mm| mm.columnheader == h}.first.methodstep.title
    end


    # The determination of Vip or Vop status only makes sense if the
    # current user is logged in
    #ToDo Was macht das?
    @submethod_list_user = []
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
    context = @context
    # Define the formats for the spreadsheet
    formats = {}
    formats[:dataformat] = Spreadsheet::Format.new :size => 11, :horizontal_align => :left, :italic => true
    formats[:metaformat] = Spreadsheet::Format.new :size => 11, :horizontal_align => :left, :color => 'brown'
    # Write the metadata sheet
    create_metasheet(book, context, formats)

    # This loop checks the Vip/Vop-status for every PersonRole, the current user plays.
    # If any status is found, the appropriate download is allowed.

    create_methodsheet(book, context, formats)
    create_peoplesheet(book, context, formats)
    create_categorysheet(book, context, formats)
    # if data sheet is too large, it has to be saved
    # as .csv file
    create_datasheet(book, context, formats)
    # this should be basename and then the number of the download
    filename = "download#{context.downloads}_#{context.filename}"

    # Write the book to the stream and send it back to the browser
    book.write(report)
    send_data report.string, :content_type => "application/xls", :filename => filename

    # Add 1 to the download counter
    context.downloads = (context.downloads || 0) + 1
    context.save
  end

  protected
  
  # Creates the first sheet of a context file, the one with the
  # metadata.
  def create_metasheet(book, context, formats)
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
    sheet[11,0] = "Projects (e.g.: sp1e, sp11c):"
    sheet[11,1] = context.projecttag_list

    sheet[13,0] = t('metadata.people')
    sheet[14,0] = t('metadata.givenname')
    sheet[15,0] = t('metadata.surname')
#    sheet[14,0] = t('metadata.project')
#    sheet[15,0] = t('metadata.organization')
#    sheet[16,0] = t('metadata.city')
    sheet[16,0] = t('metadata.email')
#    sheet[18,0] = t('metadata.role')

    c_owners = context.people.select{|p| p.has_role?(:owner, context)}
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
          sheet[16,i] = cpr.person_addresses[0].email unless cpr.person_addresses.blank?
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
  def create_methodsheet(book, context, formats, methods = nil)
    # This action canot be called externally.

    #Create the sheet and fill in the headers
    sheet = book.create_worksheet :name => 'Column description'

    sheet.row(0).default_format = formats[:metaformat]
    sheet.row(0).height = 120

    sheet[0,0] = "Column header"
    sheet[0,1] = "Definition"
    sheet[0,2] = "Unit of measurement"
    sheet[0,3] = "Missing value code"
    sheet[0,4] = "Comments related to this data column"
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
      mms = MeasurementsMethodstep.find(:all, :conditions => ["context_id = ?", context.id], :order => "columnnr ASC")      
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

      sheet[row,5] = datacolumn.methodstep.title if datacolumn.methodstep.title
      sheet[row,6] = datacolumn.methodstep.description if datacolumn.methodstep.description
      sheet[row,7] = datacolumn.methodstep.instrumentation if datacolumn.methodstep.instrumentation
      sheet[row,8] = datacolumn.methodstep.informationsource if datacolumn.methodstep.informationsource
      sheet[row,9] = datacolumn.methodstep.methodvaluetype if datacolumn.methodstep.methodvaluetype
      sheet[row,10] = datacolumn.methodstep.timelatency if datacolumn.methodstep.timelatency
      sheet[row,11] = datacolumn.methodstep.timelatencyunit if datacolumn.methodstep.timelatencyunit
    end
  end

  # Creates the third sheet of a context file, the one with the people
  # involved.  If no Method are given, all people of the context will
  # be listed.
  def create_peoplesheet(book, context, formats, methods = nil)
    # This action canot be called externally.

    sheet = book.create_worksheet :name => 'Column responsible persons'

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
      mms = MeasurementsMethodstep.find(:all, :conditions => ["context_id = ?", context.id], :order => "columnnr ASC")      
    end

    row = 1
    mms.each do |step|
      step.people.each do |pr|
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
  # the categoric descriptions.  If no Method are given, all
  # appropriate categories of the context will be listed.
  def create_categorysheet(book, context, formats, methods = nil)
    # This action canot be called externally.

    sheet = book.create_worksheet :name => 'column categories'    

    sheet.row(0).default_format = formats[:metaformat]
    sheet.row(0).height = 120
    sheet[0,0] = "Column header"
    sheet[0,1] = "Category short"
    sheet[0,2] = "Category long"
    sheet[0,3] = "Category description"

    if methods
      # If methods are given, use the given methods.
      mms = methods
    else
      # If no methods are given, use all methods of the context.
      mms = MeasurementsMethodstep.find(:all, :conditions => ["context_id = ?", context.id], :order => "columnnr ASC")      
    end

    mms_cat = []
    mms.each do |mm|
      # Each MeasurementsMethodstep is tested if it contains categories.
      # If it's categoric, we want to have this MeasurementsMethodstep.
      firstMeas = mm.measurements.first
      unless firstMeas.nil?
        if firstMeas.value_type == "Categoricvalue"
          mms_cat << mm
        end
      end
    end
    mms_cat = mms_cat.uniq

    row = 1
    m_old = []
    mms_cat.each do |step|
      step.measurements.sort{|a,b| a.value.short <=> b.value.short}.each do |m|
        unless m_old.include?(m.value.long) || m.value.long == m.value.description
          sheet.row(row).default_format = formats[:dataformat]
          sheet[row,0] = step.columnheader
          sheet[row,1] = m.value.short
          sheet[row,2] = m.value.long
          sheet[row,3] = m.value.description

          m_old << m.value.long
          row += 1
        end
      end
    end
  end

  # Creates the last sheet of a context file, the one that contains the raw data.
  # If no Method are given, all people of the context will be listed.
  def create_datasheet(book, context, formats, methods = nil)
    # This action canot be called externally.

    sheet = book.create_worksheet :name => 'Raw data'    

    if methods
      # If methods are given, use the given methods.
      mms = methods
    else
      # If no methods are given, use all methods of the context.
      mms = MeasurementsMethodstep.find(:all, :conditions => ["context_id = ?", context.id], :order => "columnnr ASC")      
    end

    column = 0
    mms.each do |datacolumn|
      if methods
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
     
      datacolumn.measurements.each do |m|
        # Each Measurement is rendered in its proper cell
        if m.value_type == "Datetimevalue"
          if datacolumn.import_data_type == "year"
            value = m.value.year
          elsif datacolumn.import_data_type == "date(14.07.2009)"
            value = m.value.date.to_date.to_s
          elsif datacolumn.import_data_type == "date(2009-07-14)"
            value = m.value.date.to_date.to_s
          end
        else
          value = case m.value_type
                  when "Categoricvalue" then m.value.short
                  when "Numericvalue" then m.value.number
                  when "Datetimevalue" then m.value.year
                  when "Textvalue" then m.value.text
                  when "Filevalue" then m.file_file_name
                  end
        end

        
        #! here m.rownr will have to be replaced with
        #! m.observation.rownr, as soon as observations are directly
        #! linked to measurements
        sheet[m.observation.rownr-1,column-1] = value if value
      end
    end
  end

  def load_context
    @context = Context.find(params[:id])
  end


  # Asks if object is a valid float.  Should not be in this
  # controller, but accessible from anywhere.
  def numeric?(object)
    result = false
    if object.class == String
      if object.at(0) == "0"
        if object.at(1) == "."
          result = true if Float(object) rescue false
        else
          result = false
        end
      else
        result = true if Float(object) rescue false
      end
    else
      result = true if Float(object) rescue false
    end
    result
  end



  # Asks if object is a valid integer.
  def integer?(object)
    if numeric?(object)
      object = object.to_f
      mod = object.modulo(1)
      if mod == 0
        true
      else
        false
      end
    else
      false
    end
  end


end
