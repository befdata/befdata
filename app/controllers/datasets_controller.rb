class DatasetsController < ApplicationController


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
        if filevalue.dataset.blank?
          @dataset = Dataset.new
          @dataset.upload_spreadsheet = filevalue

          # gather all the cell values that can just be copied into
          # the new context
          filename = filevalue.file_file_name
          simple_hash = gather_simple_general_metadata(filename, book)
          @dataset.update_attributes(simple_hash)

          logger.debug "-- data conversion --"
          datemin = Array(book.worksheet(0).column(0))[32].to_s
          logger.debug "-- datemin #{datemin} --"
          day_month = "1/1/"
          @dataset.datemin = parse_date_txt(datemin, day_month)
          datemax = Array(book.worksheet(0).column(0))[34].to_s
          logger.debug "-- datemax #{datemax} --"
          day_month = "12/31/"
          @dataset.datemax = parse_date_txt(datemax, day_month)



          @dataset.save
          logger.debug "---------- after saving the new context -------"
          logger.debug @dataset.valid?
          logger.debug @dataset.errors.inspect


          # Gather the people
          # Determine number of people
          cols = Array(book.worksheet(0).row(14)).length
          ppl = cols - 1 # The first column contains only meta data
          logger.debug "------------ ppl.inspect  ---------"
          logger.debug ppl.inspect

#          # The current user is automatically added to the user array
#          logger.debug "---------- after saving the new context -------"
#          people = [@current_user]
          users = []

          ppl.times do |i| # starts at 0
            person = Array(book.worksheet(0).column(i+1))[14..15]
            logger.debug "------------ person.inspect  ---------"
            logger.debug person.inspect
            # Look for the givenName in both name fields
            users += User.find_all_by_firstname(person[0])

            # Look for the surName in both name fields
            users += User.find_all_by_lastname(person[1])

            # Additionally, do a fuzzy search on both name values
            # people += Person.fuzzy_find(person[0]) # givenName
            # people += Person.fuzzy_find(person[1]) # surName

            users = users.uniq # Eliminate the doubled entries
          end


          # Add all found roles to the context. Evaluation of
          # correctness will be step 2
          users.each do |pr|
            pr.has_role! :owner, @dataset
          end

        else # there already is context information for this file
          @dataset = filevalue.dataset
        end

        # Project Tag list
        proj_tag_list = Array(book.worksheet(0).column(1))[11]
        if proj_tag_list
          @dataset.projecttag_list = proj_tag_list
        end
        @dataset.save

        # Render the page that presents the general metadata for a
        # data set, for user interaction
        # (view/contexts/upload.html.erb)
        @step = 1
        @people_list = User.find(:all, :order => :lastname)
      rescue Ole::Storage::FormatError
        # Uploaded file was no valid Excel file
        redirect_to data_path and return
      end

    elsif params[:step] == '1'
      # At this point, the parameter "filename" is given; there has
      # already an upload been done, the context for which "upload"
      # is called is already existing.  Because of this, the upload
      # of a file is leaped over.  We are at step 1.
      @dataset = Dataset.find(params[:id])
      unless @dataset.blank?

        users = User.find(params[:people])

        # assigning provenance information: linking people to the data
        # set
        users.each do |pr|
          pr.has_role! :owner, @dataset
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
        redirect_to url_for(:controller => :import,
                            :action => :raw_data_overview,
                            :context_id => @dataset.id) and return

      else
        # No context found
        redirect_to data_path and return
      end
    elsif params[:step] == '5'
      @step = 5
      logger.debug " entering step 5 "

      @dataset = Dataset.find(params[:context_id])
      logger.debug " loading context "
      logger.debug @dataset.inspect

      unless @dataset.blank?
        # Upoading and evaluation finished
        logger.debug "Upoading and evaluation finished, showing params[:finished]"
        logger.info params[:finished]
        @dataset.finished = params[:finished]
        @dataset.save


        # If the context is finished, show it
        if @dataset.finished == true
          logger.debug "After all, rebuild the search index"
          # After all, rebuild the search index
          begin
            #TODO INDEX doesnt work without Ferret
            #Dataset.rebuild_index
            logger.debug "rebuilding done"
          rescue
            logger.debug "rebuilding did not work"
          end

          redirect_to url_for :controller => :datasets,
                              :action => :show,
                              :id => @dataset.id and return
        else
          logger.debug "context not finished"
          logger.debug [@dataset.id, @dataset.title].to_s
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
