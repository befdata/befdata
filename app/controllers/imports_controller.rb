# This file controlls the import of an BEF-China workbook into the
# data portal.  It opens the file uploaded to the data portal and
# stores it's values in the data base.  It then goes through data and
# metadata interactively to verify the correctness of the data.  For
# opening the workbook we currently rely on the ruby-package
# "spreadsheet".  This has to be changed here to adapt to other
# formats such as Open Office or .xlsx files.

#require 'spreadsheet'

class ImportsController < ApplicationController


  def create_dataset_filevalue
    filevalue = Filevalue.new(params[:filevalue])

    if filevalue.save
        redirect_to :controller => :datasets, :action => :upload, :filevalue_id => filevalue.id
    else
      flash[:errors] = filevalue.errors
      redirect_to :back
    end
  end

  def raw_data_overview
    logger.debug "------------ just entered raw_data_overview  ---------"
    store_location

    
    @dataset ||= Dataset.find(params[:dataset_id], :include => [:datacolumns])

    # import information from the spreadsheet
    filevalue = @dataset.upload_spreadsheet
    filepath = filevalue.file.path

    # provides @methodsheet, @respPeopleSheet, @categorySheet,
    # @rawdatasheet,
    # @columnheadersRaw: Array of the columnheaders
    # @checkUnique: are they unique?
    # @ch_people_hash: {0=>"Column header", 1=>"rarefy_100", ...
    # @ch_cat_hash: {0=>"Column header", 1=>"rarefy_100", ...
    provide_metasheets(filepath)

    logger.debug "------------ after loading metasheet ---------"
    logger.debug @columnheadersRaw.inspect

    # Are there data columns already associated to this Dataset?
    n_data_cols = @dataset.datacolumns.length

    if n_data_cols == 0 # which means that there are no observations
                        # nor measurements

      if @checkUnique # we can only go on, if column headers of data
                      # columns are unique
        # generate data column instances
        @columnheadersRaw.each do |ch|
          logger.debug "- having entered header loop (#{ch}) -"

          # Data column information
          col_nr_raw_data = 1 + Array(@rawdatasheet.row(0)).index(ch)
          data_column_ch =
            data_column_info_for_columnheader(ch, @methodsheet,
                                              col_nr_raw_data, @dataset.id)

          logger.debug "----------  Data_Group information ---------------"
          data_group_ch = methodsheet_datagroup(ch, @methodsheet)
          logger.debug data_group_ch.inspect


          logger.debug "- Create new data group if no match is found --"
          data_group = Datagroup.find_by_title(data_group_ch[:title])
          if data_group.blank?
            logger.debug "- Creating new data group  -"
            data_group = Datagroup.create(data_group_ch)
          end
          logger.debug data_group.inspect

          logger.debug "------------  update data column information ---------"
          data_column_ch[:datagroup_id] = data_group.id
          logger.debug data_column_ch.inspect

          logger.debug "------------ create new data column ------- "
          data_column_new = Datacolumn.create(data_column_ch)
          logger.debug data_column_new.inspect
          logger.debug "-- add tags --"
          unless data_column_new.comment.blank?
            tags_new = data_column_new.comment
            data_column_new.tag_list = tags_new
            data_column_new.save
          end

          data_hash = data_for_columnheader(ch)[:data]
          unless data_hash.blank?
            logger.debug "- create all measurements  -"
            logger.debug "- Zeitchlucker?:  before @Dataset.rownr_observation_id_hash -"
            rownr_obs_hash = @dataset.rownr_observation_id_hash
            logger.debug "------------ after @Dataset.rownr_observation_id_hash ---------"
            logger.debug @dataset.rownr_observation_id_hash.inspect

            # Go through each entry in the spreadsheet
            data_hash.each do |rownr, entry|
              # Is there an observation in this Dataset with this rownr?
              # "select{} writes an array of [rnr, obs_id], but since
              # there should be only one obs_id per rownr, this can be
              # flattened and the second array object corresponds to the
              # observation Id.
              obs_id = rownr_obs_hash.
                select{|rnr, obs_id| rnr == rownr}.flatten[1]

              # If not, create a new Observation
              if obs_id.nil?
                obs = Observation.create(:rownr => rownr)
                obs_id = obs.id
              end

              # create measurement (with value as import_value)
              entry = entry.to_i.to_s if integer?(entry)
              Measurement.create(:measurements_methodstep => data_column_new,
                                 :observation_id => obs_id,
                                 :import_value => entry)
            end # is there data provided?
          end
        end
      end

      # reload Dataset
      @dataset = Dataset.find(@dataset)
    end

    #    else
#      # Not logged in, redirect to login form
#      session[:return_to] = request.request_uri
#      redirect_to login_path and return
#    end
  end # raw data overview


  # After the general metadata of a data set has been saved to a
  # Context in the ContextsController and after the cell entries in
  # the raw data sheet have been saved in Measurement instances
  # (raw_data_overview), this method manages provenance information as
  # well as data checking and allocation to value tables
  # (Numericvalue, Categoricvalue, etc).
  def raw_data_per_header
    benchmark_time = Time.new
    logger.debug "---------- in raw_data_per_header ---------------"
    @dataset ||= Dataset.find(params[:dataset_id],
                              :include => [:datacolumns ,
                                           :upload_spreadsheet])
    @data_column ||= @dataset.datacolumns.
      select{|dc| dc.columnheader == params[:data_header]}.first

    # open the spreadsheet
    filepath = @dataset.upload_spreadsheet.file.path
    provide_metasheets(filepath)

    # data column specific information: start with the column header
    ch = @data_column.columnheader


    method_index = Array(@methodsheet.column(0)).index(ch)
    unless method_index.blank?
      data_group_Title = Array(@methodsheet.column(5))[method_index]
    else
      data_group_Title = ch
    end
    logger.debug "------ before looking for similar methods --- "
    logger.debug "----- #{Time.new - benchmark_time} ms"
    methAvailable = find_similar_data_groups(data_group_Title)
    logger.debug "----- #{Time.new - benchmark_time} ms"
    logger.debug "------ after looking for similar methods --- "
    @data_groups_available = methAvailable
    logger.debug "@data_groups_available"
    logger.debug @data_groups_available.inspect

    # collect all methods for the select button
    all_methods = Datagroup.find(:all, :order => "title")
    @methods_short_list = all_methods.collect{|m| [m.title, m.id]}

    # prepare a new data group instance to save it if needed
    data_group_ch = methodsheet_datagroup(ch, @methodsheet)
    @data_group_new = Datagroup.new(data_group_ch)
    logger.debug "@data_group_new"
    logger.debug @data_group_new.inspect

    # list of all Person Roles, sorted
    logger.debug "------------------- Person Roles -----------------"
    @people_list = User.find(:all, :order => :lastname)

    # Are there already people associated?
    @ppl = @data_column.users

    # Only look into the spreadsheet, if there are no people linked.
    logger.debug "----- #{Time.new - benchmark_time} ms"
    if @ppl.blank?
      ppl = lookup_data_header_people(ch)
      ppl = ppl.flatten.uniq
      ppl.each do |user|
        user.has_role! :responsible, @data_column
      end
      @ppl = @data_column.users
    end
    logger.debug "--- after filling @prs mit 'lookup_data_header_people(ch)' ---"
    logger.debug @ppl.inspect


    # raw data

    # returns a data hash with rownr => data entry from the
    # spreadsheet !Zeitschlucker?!
    @cell_values_all = @data_column.rownr_entry_hash
    logger.debug "---------- @cell_values_all ---------------"
    logger.debug @cell_values_all.inspect
    logger.debug "----------------------- #{Time.new - benchmark_time} ms"

    # collect all categories for this data column; Array of Categories
    @portal_cats = @data_column.datagroup.datacell_categories

    # collect all categories provided in the category sheet and
    # present them, no matter if they are double or not.  Do this only
    # if no import categories are provided yet
    if @data_column.import_categoricvalues.blank?
      sheet_cats_hash_array =  look_for_provided_cats(ch,
                                                      @categorySheet)

      sheet_new_cats = sheet_cats_hash_array.
        map{|cat_info| Categoricvalue.create(cat_info)}

      sheet_new_imp_cats = sheet_new_cats.
        map{|cat| ImportCategoricvalue.new(:categoricvalue => cat)}

      @data_column.import_categoricvalues = sheet_new_imp_cats

    end

    @sheet_cats = @data_column.import_categoricvalues.
      map{|imp_c| [imp_c.categoricvalue.id,
                   imp_c.categoricvalue.short,
                   imp_c.categoricvalue.long]}


    all_values = @data_column.measurements_sorted.
      collect{|m| m.value}
    full_values = all_values.compact
    @first_meas = full_values[0..20].
      collect{|v| v.show_value}.to_sentence

    logger.debug "---------- leaving raw_data_per_header ---------------"
    logger.debug "----------------------- #{Time.new - benchmark_time} ms"
  end


  def update_data_header
    if current_user
      data_header = Datacolumn.find(params[:datacolumn][:id])

      if data_header.update_attributes(params[:datacolumn])
        redirect_to :back
      else
        redirect_to data_path
      end

    else
      # Not logged in, redirect to login form
      session[:return_to] = request.request_uri
      redirect_to login_path and return
    end
  end

  def update_data_group
    if current_user
      data_header = Datacolumn.find(params[:datacolumn][:id])
      data_group = Datagroup.new(params[:datagroup])

      logger.debug "--------------------------------------------------"
      logger.debug data_header.inspect
      logger.debug data_group.inspect
      logger.debug params.inspect

      begin
        Datacolumn.transaction do
          if data_group.save
            data_header.datagroup = data_group
            data_header.save
            redirect_to :back
          end
        end
      rescue ActiveRecord::RecordInvalid => invalid
        redirect_to :root
      end
    else
      # Not logged in, redirect to login form
      session[:return_to] = request.request_uri
      redirect_to login_path and return
    end
  end

# Assingning provenance informaiton: linking people to a data column
  def update_people_for_data_header
    if logged_in?
      data_column = MeasurementsMethodstep.find(params[:measurements_methodstep][:id])
      people = Person.find(params[:people])

      # assigning provenance information: linking people to a data
      # column
      people.each do |pr|
        pr.has_role! :responsible, data_column
      end
      redirect_to :back
    else
      # Not logged in, redirect to login form
      session[:return_to] = request.request_uri
      redirect_to login_path and return
    end
  end

   # Adding data values to data columns.  Values are imported from the
  # workbook that has been uploaded in the ContextsController.  We
  # save the identity of the cell, in which the value is stored (see
  # Measurement) as well as value itself.  Values are distributed
  # across a limited set of tables, Categoricvalue, Datetimevalue,
  # Numericvalue, and Textvalue.  Apart from data columns in
  # workbooks, one may also save free format files.  (!! We still have
  # to write the views etc for that!!)
  def add_data_values
    if current_user
      data_column =
        Datacolumn.find(params[:datacolumn][:id])
      data_column.update_attributes(params[:data_column])

      # Text values do not have associated categoric values (naming
      # conventions), all the others have.  This is because the
      # scientists wanted to have different options in describing
      # types of missing values.
      if data_column.import_data_type == "text"
        text_data_column_import(data_column.id)
      else
        logger.debug "------------ looking for naming conventions  ---------"
        portal_cats = data_column.datagroup.datacell_categories
        sheet_cats = data_column.import_categoricvalues.
          map{|icat| icat.categoricvalue}
        if data_column.import_data_type == "category"
          category_data_column_import(data_column.id, portal_cats,
                                      sheet_cats)
        elsif data_column.import_data_type == "number"
          numeric_data_column_import(data_column.id, portal_cats,
                                     sheet_cats)
        elsif data_column.import_data_type == "date(14.07.2009)"
          datetime_data_column_import(data_column.id, portal_cats,
                                      sheet_cats)
        elsif data_column.import_data_type == "date(2009-07-14)"
          datetime_data_column_import(data_column.id, portal_cats,
                                      sheet_cats)
        elsif data_column.import_data_type == "year"
          year_data_column_import(data_column.id, portal_cats,
                                  sheet_cats)
        end
      end

      # by now values have been added
      unless data_column.categories.blank?
        redirect_to(:controller => :import,
                    :action => :data_column_categories,
                    :data_column_id => data_column.id)
      else
        redirect_to :back
      end

    else
      # Not logged in, redirect to login form
      session[:return_to] = request.request_uri
      redirect_to login_path and return
    end
  end
  


private
  def provide_metasheets(filename)
    ## open the spreadsheet and locate the next column to import
    ##  require 'spreadsheet'

    book = Spreadsheet.open filename
    book.io.close

    ## specify location of sheets
    @methodsheet = book.worksheet(1)
    @respPeopleSheet = book.worksheet(2)
    @categorySheet = book.worksheet(3)
    @rawdatasheet = book.worksheet(4)

    ## assemble the information on raw data from the last sheet
    @columnheadersRaw = Array(@rawdatasheet.row(0)).compact

    ## there are several people associated to one columnheader
    ch_people = Array(@respPeopleSheet.column(0))
    @ch_people_hash = {}
    ch_people.each_index do |x|
      @ch_people_hash[x] = ch_people[x]
    end
    @ch_people_hash.delete_if{|k,v| v.nil?}

    ## there are several entries for categories for each columnheader
    ch_cat = Array(@categorySheet.column(0))
    @ch_cat_hash = {}
    ch_cat.each_index do |x|
      @ch_cat_hash[x] = ch_cat[x]
    end
    @ch_cat_hash.delete_if{|k,v| v.nil?}

    ## each context should have unique columnheaders
    @checkUnique = @columnheadersRaw.length == @columnheadersRaw.uniq.length

    # if columnheaders are not unique, they have to be renamed at this
    # point. Before submethods are saved, the columnheaders have to be
    # unique

  end

  def data_column_info_for_columnheader(columnheader, methodsheet,
                                   raw_data_col_nr, data_set_id)
    logger.debug "-------- in method_info_for_columnheader ------------"
    ch = columnheader
    method_index = Array(methodsheet.column(0)).index(ch)
    logger.debug "------------ method_index   ----------"
    logger.debug method_index.inspect

    # Submethod information
    unless method_index.nil?
      data_header_Def = Array(methodsheet.column(1))[method_index]
      data_header_Def = ch if data_header_Def.blank?
      data_header_Unit = Array(methodsheet.column(2))[method_index]
      data_header_Missing = Array(methodsheet.column(3))[method_index]
      data_header_Comment = Array(methodsheet.column(4))[method_index]
      dc_import_data_type = Array(methodsheet.column(9))[method_index]
    else # column header does not appear in the method sheet
      data_header_Def = ch
      data_header_Unit = nil
      data_header_Missing = nil
      data_header_Comment = nil
      dc_import_data_type = nil
    end


    # return the information
    data_header_ch = {:dataset_id => data_set_id,
      :columnheader => ch,
      :columnnr => raw_data_col_nr,
      :definition => data_header_Def,
      :unit => data_header_Unit,
      :missingcode => data_header_Missing,
      :comment => data_header_Comment,
      :import_data_type => dc_import_data_type}

    return data_header_ch

    logger.debug "-------- leaving method_info_for_columnheader ------------"
  end

  # During the upload process we look several times back in the
  # spreadsheet.  In this case, we are looking for data group
  # information (Methodstep, MethodstepsController).  Data groups
  # consist of several data column instances
  # (MeasurementsMethodstep). During first upload (raw_data_overview),
  # we use the information provided in the method sheet in columns 5
  # to 11 to guess a similar data group from the data portal.  During
  # the upload of each single data column from the raw data sheet
  # (raw_data_per_header), we use this information to initialize a new
  # data group instance which can then be altered and saved to save
  # this new data group on the portal.
  def methodsheet_datagroup(columnheader, methodsheet)
    logger.debug " in methodsheet_datagroup(columnheader) ---------- "
    ch = columnheader
    method_index = methodsheet.column(0).to_a.index(ch)
    unless method_index.nil?
      row = methodsheet.row(method_index)
      data_group_Title = row[5]
      # if not data group Title is given, date the definition of the
      # data column header
      if data_group_Title.nil?
        data_group_Title = row[1] # data column definition
        if data_group_Title.nil?
          data_group_Title = ch
        end
      end
      data_group_Descr = row[6]
      data_group_Descr = (data_group_Descr.nil? ? data_group_Title : data_group_Descr)
      data_group_Instr = row[7]
      data_group_Sourc = row[8]
      data_group_NType = row[9]
      data_group_TScal = row[10]
      data_group_TScUn = row[11]
    else # no discription for this ch in the method sheet
      data_group_Title = ch
      data_group_Descr = ch
      data_group_Instr = nil
      data_group_Sourc = nil
      data_group_NType = nil
      data_group_TScal = nil
      data_group_TScUn = nil
    end

    # summary
    data_group = {:title => data_group_Title,
      :description => data_group_Descr,
      :methodvaluetype => data_group_NType,
      :instrumentation => data_group_Instr,
      :informationsource => data_group_Sourc,
      :timelatency => data_group_TScal,
      :timelatencyunit => data_group_TScUn}
    return data_group
  end

  def data_for_columnheader(columnheader)
    logger.debug "- in data_for_columnheader (#{columnheader})  -"
    ch = columnheader
    col = Array(@rawdatasheet.row(0)).index(ch)
    data_with_head = Array(@rawdatasheet.column(col))
    if data_with_head.length > 1
      data_hash = generate_data_hash(data_with_head) # deletes dataheader
      rowmax_with_header = data_hash.keys.max
      if rowmax_with_header.nil?
        rowmax = 0
      else
        rowmax = rowmax_with_header - 1 # starting at second row
      end
      # generate lookup
      data_lookup_ch = { :data => data_hash,
        :rowmax => rowmax}
    else
      logger.debug "- no data provided (#{columnheader})  -"
      data_lookup_ch = {:data => nil, :rowmax => 1}
    end # if data length > 1

    return(data_lookup_ch)
  end

  # Takes the entire data column of a raw data sheet and converts it
  # to a hash which stores row numbers as key and the measurements
  # from the spreadsheet as hash value.  Additionally deletes the
  # first row, since this contains the columnheader and not a
  # measurement.  The row number stored here is equal to the row
  # number in the spreadsheet.
  def generate_data_hash(data_array)
    data_hash = {}
    data_array.each_index do |x|
      d = data_array[x]
      if d.class == Spreadsheet::Formula
        d = d.value
      elsif d.class == Spreadsheet::Excel::Error
        d = "Error in Excel Formula"
      end
      row = x + 1
      d = d.to_i.to_s if integer?(d)
      data_hash[row] = d unless d.nil?
    end
    # deleting the first row which contains the column header and not
    # a value
    data_hash.delete_if{|k,v| k==1}
    return(data_hash)
  end

  # Uses "ferret" to match information given in an imported workbook
  # or any text to find similar data groups (see Methodstep,
  # Admin::MethodstepsController) on the portal.
  def find_similar_data_groups(data_group_Title)

    logger.debug "---------- in find_similar_data_groups --------------"
    logger.debug "data_group_Title"
    logger.debug data_group_Title.inspect
    # find suitable methods already available
    #methAvailable = Datagroup.find_with_ferret(data_group_Title)
    methAvailable = Datagroup.find_by_title(data_group_Title)
    # now making sure that at least one known method is fund
    if methAvailable
      #TODO THIS DOESNT WORK !!!!!!!!!
      #! We should add numeric helper and text helper, use text
      #! helper if there is text in the column, and
      #methAvailable << Datagroup.find(74)
      kram = Datagroup.new(:title => "helper", :methodvaluetype => "integer", :description => "beschreibung")
      kram.save
      methAvailable = []
      methAvailable << kram
    end
    logger.debug "methAvailable"
    logger.debug methAvailable.inspect
    logger.debug "methAvailable.collect{|dg| dg.id}"
    logger.debug methAvailable.collect{|dg| dg.id}.inspect
    return methAvailable
  end

# The third sheet of the data workbook lists people which have
  # collected data found in the raw data sheet of the workbook.  These
  # people are associated to subprojects and have roles within their
  # subprojects.  These people can be asked if there are questions
  # concerning data in a given column of the raw data sheet.  These
  # people should also be considered when writing papers using the
  # data from this column in the rawdata sheet (see DataRequest and
  # DataRequestsController).
  #
  # The lookup method is only called when there are no people already
  # associated to a data header (see MeasurementsMethodstep,
  # MeasurementsMethodstepsController).
  def lookup_data_header_people(ch)
    # there are often several people for one column in raw data;
    # people can also be added automatically to the submethod
    people_rows = @ch_people_hash.select{|k,v| v==ch} # [[1, "rarefy_100"]]
    people_rows = people_rows.collect{|r_ch| r_ch[0]} # only the row index
    people_given = []
    people_sur   = []
    people_proj  = []
    people_role  = []
    people = []
    people_rows.each do |r|
      people_given << @respPeopleSheet.row(r)[1]
      people_sur   << @respPeopleSheet.row(r)[2]
      people_proj   << @respPeopleSheet.row(r)[3]
      people_role   << @respPeopleSheet.row(r)[4]
      people += User.find_all_by_lastname(people_sur)
      #TODO SEARCH HACK
      #people += Person.fuzzy_find(people_sur)
    end
    people = people.uniq
#    prs = people.collect{|p| p.person_roles}.flatten
#    prs = prs.flatten.uniq
#    prs = prs.sort_by{|pr| pr.person.lastname}
    return people
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


# Look for information from the category sheet.
  def look_for_provided_cats(columnheader, categorysheet)
    ## acronymy and descriptions provided
    prov_header = Array(categorysheet.column(0))
    prov_short = Array(categorysheet.column(1))
    prov_long = Array(categorysheet.column(2))
    prov_description = Array(categorysheet.column(3))
    ## collecting the relevant rows
    provided_hash_array = []
    (1..prov_header.length).each do |i|
      i0 = i-1
      unless prov_header[i0].nil?
        if prov_header[i0] == columnheader
          short = prov_short[i0]
          short = short.to_i.to_s if integer?(short)
          provided_hash = {:short => short,
            :long => prov_long[i0],
            :description => prov_description[i0],
            :comment => 'added from category sheet'}
          provided_hash_array << provided_hash
        end
      end
    end
    return provided_hash_array
  end
  


end
