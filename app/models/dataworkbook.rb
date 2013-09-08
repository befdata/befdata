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

  include ActiveModel::Validations
  validates_with WorkbookValidator

  attr_reader  :book

  def initialize(datafile)
    @dataset = datafile.dataset
    @book = Spreadsheet.open(datafile.path) and @book.io.close rescue nil # Close after reading, for memorys sake. (TODO: is this really necessary?)
  end

  # The general metadata sheet contains information about the data set
  # as a whole. The general_metadata method gathers the
  # contents of the text cells within this sheet.
  def general_metadata_hash
    {
      title: clean_string(general_metadata_sheet[*WBF[:meta_title_pos]]),
      abstract: clean_string(general_metadata_sheet[*WBF[:meta_abstract_pos]]),
      comment: clean_string(general_metadata_sheet[*WBF[:meta_comment_pos]]),
      usagerights: clean_string(general_metadata_sheet[*WBF[:meta_usagerights_pos]]),
      published: clean_string(general_metadata_sheet[*WBF[:meta_published_pos]]),
      spatialextent: clean_string(general_metadata_sheet[*WBF[:meta_spatial_extent_pos]]),
      temporalextent: clean_string(general_metadata_sheet[*WBF[:meta_temporalextent_pos]]),
      taxonomicextent: clean_string(general_metadata_sheet[*WBF[:meta_taxonomicextent_pos]]),
      design: clean_string(general_metadata_sheet[*WBF[:meta_design_pos]]),
      dataanalysis: clean_string(general_metadata_sheet[*WBF[:meta_dataanalysis_pos]]),
      circumstances: clean_string(general_metadata_sheet[*WBF[:meta_circumstances_pos]]),
      datemin: self.datemin,
      datemax: self.datemax
    }
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

  def wb_version
    general_metadata_sheet[*WBF[:meta_version_pos]]
  end

  # Provides an array with the headers of all raw data columns.
  def columnheaders_raw
    return @headers if defined? @headers
    @headers = raw_data_sheet.row(0).compact.map(&:strip).reject {|h| h.blank?}
    return @headers
  end

  # Checks whether the raw data headers are unique.
  def columnheaders_unique?
    columnheaders_raw.length == columnheaders_raw.uniq_by(&:downcase).length
  end

  def authors_list
    given_names = general_metadata_sheet.row(*WBF[:meta_owners_start_row])
    surnames  = general_metadata_sheet.row(*WBF[:meta_owners_start_row]+1)
    emails = general_metadata_sheet.row(*WBF[:meta_owners_start_row]+2)

    users_from_sheet_with_row_header = given_names.zip surnames, emails
    users_from_sheet = users_from_sheet_with_row_header.drop(1)
    find_users(users_from_sheet)
  end

  # Returns the tags that were in the respective cell.
  def projects_list
    project_string = general_metadata_sheet[*WBF[:meta_projects_pos]]
    return [] if project_string.blank?
    projects = project_string.split(',').map(&:squish).uniq.collect do |p|
      Project.find_by_converting_to_tag(p)
    end
    projects.compact
  end

  # Helper method to determine the correct minimal date value from the string given in the Workbook.
  def datemin
    parse_date(general_metadata_sheet[*WBF[:meta_datemin_pos]].to_s) {|year| Date.new(year, 1, 1) }
  end

  # Helper method to determine the correct maximal date value from the string given in the Workbook.
  def datemax
    parse_date(general_metadata_sheet[*WBF[:meta_datemax_pos]].to_s) {|year| Date.new(year, 12, 31) }
  end

  # The method that loads the Workbook into the database.
  def import_data
    # generate data column instances
    number_of_columns = columnheaders_raw.count
    processing_column = 1
    columnheaders_raw.each do |columnheader|
      @dataset.update_attribute(:import_status, "processing column #{processing_column} of #{number_of_columns}")
      data_column_new = save_data_column(columnheader)
      datatype = Datatypehelper.find_by_name(data_column_new.import_data_type)

      all_cells_for_one_column = data_for_columnheader(columnheader)[:data]
      unless all_cells_for_one_column.blank?
        save_all_cells_to_database(data_column_new, datatype, all_cells_for_one_column)
        add_any_sheet_categories_included_for_this_column(columnheader, data_column_new)
        add_acknowledged_people(columnheader, data_column_new)
      end

      processing_column += 1
    end
  end

  def save_data_column(columnheader)
    data_column_info, data_group_ch = parse_method_row(columnheader)

    unless data_group_ch.blank?
      datagroup = Datagroup.where(["title iLike ?", data_group_ch[:title]]).first
      if datagroup
        # if the datagroup exists check whether the Method step description
        # fields are the same. If they aren't then append them to the column definition.
        column_description = ""
        if compare_strings(datagroup.description, data_group_ch[:description])
          column_description = "; Datagroup description: #{data_group_ch[:description]}"
        end
        data_column_info[:definition] = "#{data_column_info[:definition]}#{column_description}" unless column_description.blank?
      else  # if there is no existing datagroup. create it.
        datagroup = Datagroup.create!(data_group_ch)
      end
      data_column_info.merge!(datagroup_id: datagroup.id)
    end
    Datacolumn.create!(data_column_info)
  end

  def parse_method_row(columnheader)
    method_index = method_index_for_columnheader(columnheader)

    column_info = {
      columnheader: columnheader,
      columnnr: 1 + columnheaders_raw.index(columnheader),
      datagroup_approved: false,
      datatype_approved: false,
      finished: false,
      dataset_id: @dataset.id
    }
    datagroup_info = {}

    if method_index
      row = data_description_sheet.row(method_index)
      datagroup_info.merge! grab_datagroup_info(row)
      column_info.merge! grab_column_info(row)
    end
    return [column_info, datagroup_info]
  end

  # Reverse lookup for column headers. Returns the index for any provided columnheader.
  def method_index_for_columnheader(columnheader)
    columnheaders = Array(data_description_sheet.column(0))
    columnheaders.collect!{|col| clean_string(col)}.index(columnheader)
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
    header = Array(data_responsible_person_sheet.column(*WBF[:people_columnheader_col]))
    lastnames = Array(data_responsible_person_sheet.column(*WBF[:people_lastname_col]))
    firstnames = Array(data_responsible_person_sheet.column(*WBF[:people_firstname_col]))

    names_array = [] << header << firstnames << lastnames
    names_array = names_array.transpose
    names_array.uniq!
    names_array.reject!{|x| x[0]!= columnheader}
    names_array.each{|x| x.delete columnheader}

    ppl = find_users(names_array)

    ppl[:found_users].each do |user|
      user.has_role! :responsible, data_column_new
    end
    unless ppl[:unfound_usernames].blank?
      data_column_new.update_attribute :acknowledge_unknown, ppl[:unfound_usernames].join(', ')
    end
  end

  # Extracts the datatype from the spreadsheet for a given columnheader
  def datatype_for_columnheader(columnheader)
    data_type_name = clean_string(Array(data_description_sheet.column(*WBF[:column_methodvaluetype_col]))[method_index_for_columnheader(columnheader)])
    Datatypehelper.find_by_name(data_type_name)
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
      data_hash[row] = d unless d.blank?
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
      input = input.to_s.strip
    end
    return input
  end

  def compare_strings(datagroup_string, test_string)
     unless test_string.blank?
       unless datagroup_string.blank?
         return datagroup_string.downcase != test_string.downcase
       end
       return true
     end
    return false
  end

  def parse_date(date)
    # When parse did not succeed, we have to guesstimate.
    # Is the string usable as year? If yes, use it. If no, fall back to the current year.
    Date.parse(date) rescue yield(date.to_i > 2000 ? date.to_i : Date.today.year)
  end

  def grab_datagroup_info(method_row)
    datagroup = {
      title: method_row[*WBF[:group_title_col]],
      description: method_row[*WBF[:group_description_col]],
    }
    datagroup.each{|key, value| datagroup[key] = clean_string(value)}
    return {} if datagroup[:title].blank?
    return datagroup
  end

  def grab_column_info(method_row)
    data_header_ch = {
      definition: method_row[WBF[:column_definition_col]],
      import_data_type: method_row[WBF[:column_methodvaluetype_col]],
      unit: method_row[WBF[:column_unit_col]],
      instrumentation: method_row[*WBF[:column_instrumentation_col]],
      informationsource: method_row[*WBF[:column_informationsource_col]],
      tag_list: method_row[WBF[:column_keywords_col]]
    }
    data_header_ch.each {|k,v| data_header_ch[k] = clean_string(v)}
    return data_header_ch
  end

  # gives found and unfound users
  # usernames must be an array af the formm [[firstname_1, lastname_1], [firstname_2, lastname_2]]
  def find_users (usernames = [])
    found_users = []
    unfound_usernames = []
    usernames.each do |un|
      first = clean_string(un[0])
      last = clean_string(un[1])
      unless first.nil? && last.nil?
        u = User.find_by_firstname_and_lastname(first, last)
        if u.nil?
          unfound_usernames << "#{first} #{last}"
        else
          found_users << u
        end
      end
    end
    found_users.compact!
    found_users.uniq!
    unfound_usernames.compact!
    unfound_usernames.uniq!
    {:found_users => found_users, :unfound_usernames => unfound_usernames}
  end

end
