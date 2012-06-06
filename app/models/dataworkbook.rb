## The Dataworkbook class functions as wrapper for the BEFdata Workbook, an MS Excel 2003 file containing
## the raw data array in one sheet and four separate sheets providing metadata.  The "General Metadata" sheet
## provides information on the context of the data set (general_metadata_sheet, general_metadata_column, general_metadata_hash),
## while the "Technical description" (data_desciption_sheet, data_column_info_for_columnheader),
## "Acknowledgments" (data_responsible_person_sheet, columnheader_people), and
## "Categories" (data_categories_sheet, sheet_categories_for_columnheader) sheets provide information
## on each single column of data from the "Raw data" sheet.
##
## The column headers in the raw data sheet of the BEFdata Workbook function as foreign IDs connecting metadata
## to the raw data columns. It is thus essential that the column headers in the raw data sheet are
## unique (columnheaders_unique?).
##
## Information provided on the general metadata sheet and on the acknowledgement sheet manages provenance in
## relation to Project and User classes.  Information on the technical description sheet directs the import workflow
## of raw data entries to the Datacolumn, Datagroup, and Sheetcell classes.  For the validation process of
## raw data values the Datatype and Sheetcellstatus classes are used.

require "dataworkbook_format"
class Dataworkbook
  include DataworkbookFormat

  attr_reader :datafile, :book

  def initialize(datafile)
    @datafile = datafile
    @dataset = @datafile.dataset
    open_datafile_from_disk
  end

  def open_datafile_from_disk
    @book = Spreadsheet.open @datafile.file.path
    # Close after reading, for memorys sake.#Todo is this really necessary?
    @book.io.close
  end

  # The general metadata sheet contains information about the data set
  # as a whole. The general_metadata method gathers the
  # contents of the text cells within this sheet.
  def general_metadata_hash
    metadata = Hash.new
    metadata[:filename] = @datafile.file_file_name
    metadata[:downloads] = 0

    metadata[:title] = clean_string(general_metadata_sheet[*WBF[:meta_title_pos]])
    metadata[:abstract] = clean_string(general_metadata_sheet[*WBF[:meta_abstract_pos]])
    metadata[:comment] = clean_string(general_metadata_sheet[*WBF[:meta_comment_pos]])
    metadata[:usagerights] = clean_string(general_metadata_sheet[*WBF[:meta_usagerights_pos]])
    metadata[:published] = clean_string(general_metadata_sheet[*WBF[:meta_published_pos]])
    metadata[:spatialextent] = clean_string(general_metadata_sheet[*WBF[:meta_spatial_extent_pos]])
    metadata[:temporalextent] = clean_string(general_metadata_sheet[*WBF[:meta_temporalextent_pos]])
    metadata[:taxonomicextent] = clean_string(general_metadata_sheet[*WBF[:meta_taxonomicextent_pos]])
    metadata[:design] = clean_string(general_metadata_sheet[*WBF[:meta_design_pos]])
    metadata[:dataanalysis] = clean_string(general_metadata_sheet[*WBF[:meta_dataanalysis_pos]])
    metadata[:circumstances] = clean_string(general_metadata_sheet[*WBF[:meta_circumstances_pos]])
    return metadata
  end

  # Returns the object representing the general metadata sheet.
  def general_metadata_sheet
    @book.worksheet(WBF[:metadata_sheet])
  end

  # Returns the object representing the second data description sheet.
  def data_description_sheet 
    @book.worksheet(WBF[:columns_sheet])
  end

  # Returns the object representing the responsible people sheet.
  def data_responsible_person_sheet
    @book.worksheet(WBF[:people_sheet])
  end

  # Returns the object representing the categories sheet.
  def data_categories_sheet
    @book.worksheet(WBF[:category_sheet])
  end

  # Returns the object representing the raw data sheet.
  def raw_data_sheet
    @book.worksheet(WBF[:data_sheet])
  end

  # Provides an array with the headers of all raw data columns.
  def columnheaders_raw
    columns = Array(raw_data_sheet.row(0)).compact
    columns = columns.collect!{ |col| clean_string(col) } unless columns.nil?
    columns
  end

  # Checks whether the raw data headers are unique.
  def columnheaders_unique?
    columnheaders_raw.length == columnheaders_raw.uniq.length
  end

  def members_listed_as_responsible
    given_names = general_metadata_sheet.row(*WBF[:meta_owners_start_row])
    surnames  = general_metadata_sheet.row(*WBF[:meta_owners_start_row]+1)
    emails = general_metadata_sheet.row(*WBF[:meta_owners_start_row]+2)

    users_from_sheet_with_row_header = given_names.zip surnames, emails
    users_from_sheet = users_from_sheet_with_row_header.drop(1)
    users_from_sheet
  end

  def portal_users_listed_as_responsible
    portal_users = []
    if @book.nil?
      load_datafile
    end
    members_listed_as_responsible.each do |member|
      portal_users << User.find_by_firstname_and_lastname(clean_string(member[0]), clean_string(member[1]))
    end
    portal_users.compact
  end

  # Returns the tags that were in the respective cell.
  def tag_list
    clean_string(general_metadata_sheet[*WBF[:meta_projects_pos]])
  end

  # Helper method to determine the correct minimal date value from the string given in the Workbook.
  def datemin
    # Retrieve the value from the Workbook.
    value = general_metadata_sheet[*WBF[:meta_datemin_pos]].to_s
    begin
      # Try to parse it as a date.
      date = Date.parse(value)
    rescue ArgumentError
      # When parse did not succeed, we have to guesstimate.
      # Is the string usable as year? If yes, use it. If no, fall back to the current year.
      year = value.to_i > 2000 ? value.to_i : Date.today.year

      # Create a new date object from the guesstimated year.
      # Use the first of January as day and month values.
      date = Date.new(year, 1, 1)
    end
    return date
  end

# Helper method to determine the correct maximal date value from the string given in the Workbook.
  def datemax
    # Retrieve the value from the Workbook.
    value = general_metadata_sheet[*WBF[:meta_datemax_pos]].to_s
    begin
      # Try to parse it as a date.
      date = Date.parse(value)
    rescue ArgumentError
      # When parse did not succeed, we have to guesstimate.
      # Is the string usable as year? If yes, use it. If no, fall back to the current year.
      year = value.to_i > 2000 ? value.to_i : Date.today.year
      
      # Create a new date object from the guesstimated year.
      # Use the last of December as day and month values.
      date = Date.new(year, 12, 31)
    end
    return date
  end

  # The method that loads the Workbook into the database.
  def import_data
    # generate data column instances
    number_of_columns = columnheaders_raw.count
    processing_column = 1
    columnheaders_raw.each do |columnheader|
      @dataset.update_attribute(:import_status, "processing column #{processing_column} of #{number_of_columns}")
      data_column_information = initialize_data_column_information(columnheader)
      data_column_new = Datacolumn.create!(data_column_information)
      all_cells_for_one_column = data_for_columnheader(columnheader)[:data]
      datatype = Datatypehelper.find_by_name(data_column_information[:import_data_type])

      unless all_cells_for_one_column.blank?
        save_all_cells_to_database(data_column_new, datatype, all_cells_for_one_column)
        add_any_sheet_categories_included_for_this_column(columnheader, data_column_new)
        add_acknowledged_people(columnheader, data_column_new)
      end
      data_column_new.finished = true

      processing_column += 1
    end
  end

  def initialize_data_column_information(columnheader)
    data_group_ch = methodsheet_datagroup(columnheader)
    data_group = Datagroup.find_by_title(data_group_ch[:title])
    if data_group.blank?
      data_group = Datagroup.create(data_group_ch)
    else
      # if the datagroup exists check that the Method step description, Instrumentation and Identification source
      # fields are the same. If they aren't then append them to the column definition.
      column_description = ""
      if compare_strings(data_group.description,data_group_ch[:description])
        column_description = "; Datagroup description: #{data_group_ch[:description]}"
      end
      if compare_strings(data_group.instrumentation,data_group_ch[:instrumentation])
        column_description = "#{column_description}; Instrumentation: #{data_group_ch[:instrumentation]}"
      end
      if compare_strings(data_group.informationsource,data_group_ch[:informationsource])
        column_description = "#{column_description}; Source: #{data_group_ch[:informationsource]}"
      end
    end

    data_column_information = data_column_info_for_columnheader(columnheader)
    #data_column_information[:definition] << column_description unless column_description.blank?
    data_column_information[:definition] = "#{data_column_information[:definition]}#{column_description}" unless column_description.blank?
    data_column_information[:dataset_id] = @dataset.id
    data_column_information[:tag_list] = data_column_information[:comment] unless data_column_information[:comment].blank?
    data_column_information[:datagroup_id] = data_group.id
    data_column_information[:datagroup_approved] = false
    data_column_information[:datatype_approved] = false
    data_column_information[:finished] = false

    data_column_information
  end

  def save_all_cells_to_database(data_column_new, datatype, all_cells)
      sheetcells_to_be_saved = []

    columns = [:datacolumn_id, :row_number, :import_value, :datatype_id, :status_id]
    all_cells.each do |row_number, cell_content|
      sheetcells_to_be_saved << [ data_column_new.id,
                                                row_number,
                                               cell_content,
                                               datatype.id,
                                               Sheetcellstatus::UNPROCESSED]
    end
    Sheetcell.import(columns, sheetcells_to_be_saved, :validate => false)
  end

  def add_any_sheet_categories_included_for_this_column(columnheader, data_column_new)
    sheet_categories = sheet_categories_for_columnheader(columnheader)
    unless sheet_categories.blank?
      sheet_categories.each do | cat |
        ImportCategory.create(:datacolumn => data_column_new,
                              :short => cat[:short],
                              :long => cat[:long],
                              :description => cat[:description])
      end
    end
  end

  def add_acknowledged_people(columnheader, data_column_new)
    ppl = lookup_data_header_people(columnheader)
    ppl = ppl.flatten.uniq
    ppl.each do |user|
      user.has_role! :responsible, data_column_new
    end
  end

  # Reverse lookup for column headers. Returns the index for any provided columnheader.
  def method_index_for_columnheader(columnheader)
    columnheaders = Array(data_description_sheet.column(0))
    columnheaders.collect!{|col| clean_string(col)}.index(columnheader)
  end

  # Returns a hash filled with all informations regarding a given columnheader.
  def data_column_info_for_columnheader(columnheader)
    method_index = method_index_for_columnheader(columnheader)

    data_header_ch = {}
    data_header_ch[:columnheader] = columnheader
    data_header_ch[:columnnr] = 1 + columnheaders_raw.index(columnheader)

    if method_index.nil? # columnheader does not appear in the method sheet
      data_header_ch[:definition] = columnheader
    else
      data_header_ch[:definition] = Array(data_description_sheet.column(*WBF[:column_definition_col]))[method_index].blank? ? columnheader : clean_string(Array(data_description_sheet.column(*WBF[:column_definition_col]))[method_index])
      data_header_ch[:unit] = clean_string(Array(data_description_sheet.column(*WBF[:column_unit_col]))[method_index])
      data_header_ch[:comment] = clean_string(Array(data_description_sheet.column(*WBF[:column_keywords_col]))[method_index])
      data_header_ch[:import_data_type] = clean_string(Array(data_description_sheet.column(*WBF[:group_methodvaluetype_col]))[method_index])
    end

    return data_header_ch

  end

  # Extracts the datatype from the spreadsheet for a given columnheader
  def datatype_for_columnheader(columnheader)
    data_type_name = clean_string(Array(data_description_sheet.column(*WBF[:group_methodvaluetype_col]))[method_index_for_columnheader(columnheader)])
    Datatypehelper.find_by_name(data_type_name)
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
      data_group[:title] = row[*WBF[:group_title_col]].blank? ? clean_string(row[*WBF[:column_definition_col]]) : clean_string(row[*WBF[:group_title_col]])
      data_group[:title] ||= columnheader
      data_group[:description] = row[*WBF[:group_description_col]].blank? ? clean_string(data_group[:title]) : clean_string(row[*WBF[:group_description_col]])
      data_group[:instrumentation] = clean_string(row[*WBF[:group_instrumentation_col]])
      data_group[:informationsource] = clean_string(row[*WBF[:group_informationsource_col]])
      data_group[:methodvaluetype] = clean_string(row[*WBF[:group_methodvaluetype_col]])
    end

    return data_group
  end


  # Return the complete column from the raw data sheet for a given columnheader,
  # including the header again.
  def data_with_head(columnheader)
    Array(raw_data_sheet.column(columnheaders_raw.index(columnheader)))
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
    Array(data_description_sheet.column(*WBF[:group_title_col]))[method_index_for_columnheader(columnheader)]
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
    header = Array(data_responsible_person_sheet.column(*WBF[:people_columnheader_col]))
    lastname = Array(data_responsible_person_sheet.column(*WBF[:people_lastname_col]))
    ## collecting the relevant rows
    people = []
    i=0
    for i in 0 .. header.length-1 do
      unless header[i].nil?
        if clean_string(header[i]) == columnheader
          people += User.find_all_by_lastname(clean_string(lastname[i]))
        end
      end
    end
    people.flatten.uniq
  end

  # Returns the category information from the Workbook for a given columnheader.
  def sheet_categories_for_columnheader(columnheader)

    header = Array(data_categories_sheet.column(*WBF[:category_columnheader_col]))
    short = Array(data_categories_sheet.column(*WBF[:category_short_col]))
    long = Array(data_categories_sheet.column(*WBF[:category_long_col]))
    description = Array(data_categories_sheet.column(*WBF[:category_description_col]))
    ## collecting the relevant rows
    provided_hash_array = []
    i=0
    for i in 0 .. header.length-1 do
      unless header[i].nil?
        if clean_string(header[i]) == columnheader
          d = convert_to_string(short[i])
          d = clean_string(d)
          short_text = d unless d.nil?
          #short_text = short_text.to_i.to_s if integer?(short_text)
          provided_hash = {:short => short_text,
                            :long => clean_string(long[i]),
                            :description => clean_string(description[i])
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
      d = convert_to_string(data_array[x])
      d = clean_string(d)
      row = x + 1
      data_hash[row] = d unless d.nil?
    end
    # deleting the first row which contains the column header and not
    # a value
    data_hash.delete_if{|k,v| k == 1}

    return data_hash
  end

  def convert_to_string(input)
    unless input.nil?
      if input.class == Spreadsheet::Formula
          input = input.value
      elsif input.class == Spreadsheet::Excel::Error
        input = "Error in Excel Formula"
      end
      # we can't convert to an integer as it rounds any decimals
      # the value must remain as a string
      #input = input.to_i.to_s if Integer(input) rescue false
      if(!input.blank?)
        # this regex matches any string that ends with .0 and removes it
        input = input.to_s.gsub(/(\.0)$/,'') if Integer(input) rescue false
      end
     end

    return input
  end

  ## clean_string removes any leading and trailing spaces from the input
  def clean_string(input)
    unless input.nil?
      input = input.to_s.gsub(/^[\s]+|[\s]+$/, "")
    end
    return input
  end

  def compare_strings(datagroup_string, test_string)
     unless test_string.nil? or test_string.empty?
       unless datagroup_string.nil? or datagroup_string.empty?
         return datagroup_string != test_string
       end
       return true
     end
    return false
  end

end
