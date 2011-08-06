class Dataworkbook
  # This method is automagically called for every new Dataworkbook object on creation.
  def initialize(datafile)
    # Open the povided datafile
    open(datafile)
  end

  # Opens the actual datafile from the disk and reads its content.
  def open(datafile)
    # Open the file and read its content
    @datafile = datafile
    @book = Spreadsheet.open @datafile.file.path
    
    # Close after reading, for memorys sake.
    @book.io.close
  end

  # The general metadata sheet contains information about the data set
  # as a whole. The general_metadata method gathers the
  # contents of the text cells within this sheet.
  def general_metadata_hash
    metadata = Hash.new
    metadata[:filename] = @datafile.file_file_name
    metadata[:downloads] = 0
    metadata[:finished] = false

    metadata[:title] = general_metadata_column[3]
    metadata[:abstract] = general_metadata_column[6]
    metadata[:comment] = general_metadata_column[9]
    metadata[:usagerights] = general_metadata_column[22]
    metadata[:published] = general_metadata_column[24]
    metadata[:spatialextent] = general_metadata_column[28]
    metadata[:temporalextent] = general_metadata_column[36]
    metadata[:taxonomicextent] = general_metadata_column[39]
    metadata[:design] = general_metadata_column[42]
    metadata[:dataanalysis] = general_metadata_column[45]
    metadata[:circumstances] = general_metadata_column[48]
    return metadata
  end

  # Returns the object representing the first (the general metadata) sheet.
  def general_metadata_sheet
    @book.worksheet(0)
  end

  # Returns the object representing the second (the data description) sheet.
  # Formerly called 'methodsheet'. 
  def data_description_sheet 
    @book.worksheet(1)
  end

  # Returns the object representing the third (the responsible people) sheet.
  def data_responsible_person_sheet
    @book.worksheet(2)
  end

  # Returns the object representing the fourth (the categories) sheet.
  def data_categories_sheet
    @book.worksheet(3)
  end

  # Returns the object representing the fifth (the raw data) sheet.
  def raw_data_sheet
    @book.worksheet(4)
  end

  # Wraps the general metadata column into an array.
  def general_metadata_column
    Array(general_metadata_sheet.column(0))
  end

  # Provides an array with the headers of all raw data columns.
  def columnheaders_raw
    Array(raw_data_sheet.row(0)).compact
  end

  # Checks whether the raw data headers are unique.
  def columnheaders_unique?
    columnheaders_raw.length == columnheaders_raw.uniq.length
  end

  # Returns a hash with all responsible people named in the Workbook.
  def people_names_hash
    # Determine number of responsible people in the Workbook.
    # We subtract 1 because the first column contains only meta data not actual names.
    n = Array(general_metadata_sheet.row(14)).length - 1 

    # Gather the first and last name of the reponsible people from the Workbook.
    users = []
    n.times do |i|
      users << {:firstname => Array(general_metadata_sheet.column(i+1))[14], :lastname => Array(general_metadata_sheet.column(i+1))[15]}
    end

    # Return the users.
    return users
  end

  # Returns an array of the tags that were in the respective cell.
  def tag_list
    Array(general_metadata_sheet.column(1))[11]
  end

  # Helper method to determine the correct minimal date value from the string given in the Workbook.
  def datemin
    # Retrieve the value from the Workbook.
    value = general_metadata_column[32].to_s
    begin
      # Try to parse it as a date.
      date = Date.parse(value)
    rescue ArgumentError
      # When parse did not succeed, we have to guesstimate.
      # Is the string usable as year? If yes, use it. If no, fall back to the current year.
      year = date.to_i > 2000 ? data.to_i : Date.today.year
      
      # Create a new date object from the guesstimated year.
      # Use the first of January as day and month values.
      date = Date.new(year, 1, 1)
    end
    return date
  end

# Helper method to determine the correct maximal date value from the string given in the Workbook.
  def datemax
    # Retrieve the value from the Workbook.
    value = general_metadata_column[34].to_s
    begin
      # Try to parse it as a date.
      date = Date.parse(value)
    rescue ArgumentError
      # When parse did not succeed, we have to guesstimate.
      # Is the string usable as year? If yes, use it. If no, fall back to the current year.
      year = date.to_i > 2000 ? data.to_i : Date.today.year
      
      # Create a new date object from the guesstimated year.
      # Use the last of December as day and month values.
      date = Date.new(year, 12, 31)
    end
    return date
  end

  # The method that loads the Workbook into the database.
  # This is a class method for a reason:
  # To be called by a background worker like resque, this method can't be an instance method.  
  def import_data(dataset_id)
    # Since this is a class method, we have to instantiate an object first.
    book = Dataworkbook.new(Dataset.find(dataset_id).upload_spreadsheet)

    # generate data column instances
    book.columnheaders_raw.each do |columnheader|

      # Data group available?
      data_group_ch = book.methodsheet_datagroup(columnheader)
      data_group = Datagroup.find_by_title(data_group_ch[:title])
      data_group = Datagroup.create(data_group_ch) if data_group.blank?

      # Data column information
      data_column_ch = book.data_column_info_for_columnheader(columnheader)
      data_column_ch[:dataset_id] = dataset_id
      data_column_ch[:tag_list] = data_column_ch[:comment] unless data_column_ch[:comment].blank?
      data_column_ch[:datagroup_id] = data_group.id
      data_column_ch[:datagroup_approved] = false
      data_column_ch[:datatype_approved] = false
      data_column_ch[:finished] = false
      data_column_new = Datacolumn.create(data_column_ch)

      # Retrieve tha datatype.
      datatype = Datatypehelper.find_by_name(data_column_ch[:import_data_type])
      data_hash = book.data_for_columnheader(columnheader)[:data]

      unless data_hash.blank?
        rownr_obs_hash = Dataset.find(dataset_id).rownr_observation_id_hash

        # Go through each entry in the spreadsheet
        data_hash.each do |rownr, entry|
          # Is there an observation in this Dataset with this rownr?
          obs_id = rownr_obs_hash.select{|rnr, obs_id| rnr == rownr}.flatten[1]

          # If not, create a new Observation
          if obs_id.nil?
            obs = Observation.create(:rownr => rownr)
            obs_id = obs.id
          end

          # create measurement (with value as import_value)
          #entry = entry.to_i.to_s if integer?(entry)
          sc = Sheetcell.create(:datacolumn => data_column_new,
                                :observation_id => obs_id,
                                :import_value => entry,
                                :datatype_id => datatype.id)
        end # is there data provided?

        # add any sheet categories included for this column
        sheet_categories = sheet_categories_for_columnheader(columnheader)
        unless sheet_categories.blank?
          sheet_categories.each do | cat |
            # the category should be unique within the selected datagroup
            scm_datagroup_id = Datagroup.sheet_category_match.first.id if !Datagroup.sheet_category_match.first.nil?
            unique_cat = Category.find(:first, :conditions => ["short = ? and datagroup_id=?", cat[:short].to_s, scm_datagroup_id])
            if(unique_cat.nil?)
              import_cat = Category.create(:short => cat[:short],
                                        :long => cat[:long],
                                        :description => cat[:description],
                                        :datagroup_id => scm_datagroup_id,
                                        :user_id => 1,
                                        :status_id => Categorystatus::CATEGORY_SHEET)
              if !import_cat.nil?
                unique_cat = import_cat
              end
            end
            ImportCategory.create(:category => unique_cat,
                                  :datacolumn => data_column_new)
          end
        end
      end
      data_column_new.finished = true
    end
  end

  # Reverse lookup for column headers. Returns the index for any provided columnheader.
  def method_index_for_columnheader(columnheader)
    data_description_sheet.column(0).to_a.index(columnheader)
  end

  # Returns a hash filled with all informations regarding a given columnheader.
  def data_column_info_for_columnheader(columnheader)
    method_index = method_index_for_columnheader(columnheader)

    data_header_ch = {}
    data_header_ch[:columnheader] = columnheader
    data_header_ch[:columnnr] = 1 + Array(raw_data_sheet.row(0)).index(columnheader)

    if method_index.nil? # columnheader does not appear in the method sheet
      data_header_ch[:definition] = columnheader
    else
      data_header_ch[:definition] = Array(data_description_sheet.column(1))[method_index].blank? ? columnheader : Array(data_description_sheet.column(1))[method_index]
      data_header_ch[:unit] = Array(data_description_sheet.column(2))[method_index]
      data_header_ch[:missingcode] = Array(data_description_sheet.column(3))[method_index]
      data_header_ch[:comment] = Array(data_description_sheet.column(4))[method_index]
      data_header_ch[:import_data_type] = Array(data_description_sheet.column(9))[method_index]
    end

    return data_header_ch

  end

  # During the upload process we look several times back in the
  # spreadsheet.  In this case, we are looking for data group
  # information (Methodstep, MethodstepsController).  Data groups
  # consist of several data column instances
  # (MeasurementsMethodstep). During first upload,
  # we use the information provided in the method sheet in columns 5
  # to 11 to guess a similar data group from the data portal.  During
  # the upload of each single data column from the raw data sheet
  # (raw_data_per_header), we use this information to initialize a new
  # data group instance which can then be altered and saved to save
  # this new data group on the portal.
  def methodsheet_datagroup(columnheader)

    method_index = method_index_for_columnheader(columnheader)

    data_group = {}
    if method_index.nil? # no discription for this columnheader in the method sheet
      data_group[:title] = columnheader
      data_group[:description] = columnheader
    else
      row = data_description_sheet.row(method_index)
      data_group[:title] = row[5].blank? ? row[1] : row[5]
      data_group[:title] ||= columnheader
      data_group[:description] = row[6].blank? ? data_group[:title] : row[6]
      data_group[:instrumentation] = row[7]
      data_group[:informationsource] = row[8]
      data_group[:methodvaluetype] = row[9]
      data_group[:timelatency] = row[10]
      data_group[:timelatencyunit] = row[11]
    end

    return data_group
  end

  # Once an import process was fired, 
  # this method retrieves the count of already imported sheetcells per column.
  def progress_hash
    # Get all columns.
    columns = @datafile.dataset.datacolumns
    progress = {}
    # For all columns, count the sheetcells.
    columnheaders_raw.each do |columnheader|
      progress[columnheader] = 0
      c = columns.select{|c| c.columnheader == columnheader}.first
      # Doing this directly in SQL is mind boggingly faster than doing this via ActiveRecord.
      count_query = "SELECT count(*) FROM sheetcells WHERE datacolumn_id = #{c.id}"
      values = c.blank? ? 0 : ActiveRecord::Base.connection.execute(count_query).column_values(0).first
    end
  end

  # Return the complete column from the raw data sheet for a given columnheader,
  # including the header again.
  def data_with_head(columnheader)
    Array(raw_data_sheet.column(raw_data_sheet.row(0).to_a.index(columnheader)))
  end

  # Returns a hash with al the raw data for a given columnheader.
  def data_for_columnheader(columnheader)

    data_lookup_ch = {:data => nil, :rowmax => 1}
    data = data_with_head(columnheader)
    if data.length > 1
      data_hash = generate_data_hash(data) # deletes dataheader
      data_lookup_ch[:data] = data_hash
      data_lookup_ch[:rowmax] =  data_hash.keys.max.nil? ? 0 : data_hash.keys.max - 1 # starting at second row
    end

    return data_lookup_ch
  end

  # Returns the string that represents the Data Group title for any given columnheader from the Workbook.
  def data_group_title(columnheader)
    Array(data_description_sheet.column(5))[method_index_for_columnheader(columnheader)]
  end

  # Returns a hash filled with all people for all columnheaders
  def columnheader_people
    ## there may be several people associated to one columnheader
    people_for_columnheader = {}
    data_responsible_person_sheet.column(0).to_a.compact.each_with_index{|o, i| people_for_columnheader[i] = o}
    return people_for_columnheader
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
  def lookup_data_header_people(columnheader)

    # there are often several people for one column in raw data;
    # people can also be added automatically to the submethod
    people_rows = columnheader_people.select{|k,v| v == columnheader}.keys # only the row index
    people_given = []
    people_sur   = []
    people_proj  = []
    people_role  = []
    people = []
    people_rows.each do |r|
      people_given << data_responsible_person_sheet.row(r)[1]
      people_sur << data_responsible_person_sheet.row(r)[2]
      people_proj << data_responsible_person_sheet.row(r)[3]
      people_role << data_responsible_person_sheet.row(r)[4]
      people += User.find_all_by_lastname(people_sur)
    end
    people = people.uniq
    return people
  end

  # Returns the category information from the Workbook for a given columnheader.
  def sheet_categories_for_columnheader(columnheader)

    header = Array(data_categories_sheet.column(0))
    short = Array(data_categories_sheet.column(1))
    long = Array(data_categories_sheet.column(2))
    description = Array(data_categories_sheet.column(3))
    ## collecting the relevant rows
    provided_hash_array = []
    i=0
    for i in 0 .. header.length-1 do
      unless header[i].nil?
        if header[i] == columnheader
          short_text = short[i]
          #short_text = short_text.to_i.to_s if integer?(short_text)
          provided_hash = {:short => short_text,
                            :long => long[i],
                            :description => description[i]
                          }
          provided_hash_array << provided_hash
        end
      end
    end

    return provided_hash_array
  end

  private

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
      d = d.to_i.to_s if Integer(d) rescue false
      data_hash[row] = d unless d.nil?
    end
    # deleting the first row which contains the column header and not
    # a value
    data_hash.delete_if{|k,v| k == 1}

    return data_hash
  end

end
