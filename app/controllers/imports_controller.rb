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

      begin
        Filevalue.transaction do
          filevalue.save
          #TODO should go the context upload action
          redirect_to(:controller => :datasets, :action => :upload,
                      :filevalue_id => filevalue.id)
        end
      rescue ActiveRecord::RecordInvalid => invalid
        redirect_to :back
        #TODO showing the message that file upload did not work
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


end
