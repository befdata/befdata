## The Workbook class functions as wrapper for the BEFdata Workbook, an MS Excel 2003 file containing
## the raw data array in one sheet and four separate sheets providing metadata.
##
## For details, go to https://github.com/befdata/befdata/wiki/BEFdata%20workbook
##
## Column headers are case-sensitive, 'CSP' is considered different from 'csp'
## Column headers can't be a number

require "dataworkbook_format"
class Workbook
  include DataworkbookFormat

  include ActiveModel::Validations
  validates_with WorkbookValidator

  attr_reader :book

  def initialize(datafile)
    @dataset = datafile.dataset
    @book = Spreadsheet.open datafile.path rescue nil
    @book.io.close if @book
  end

  def wb_version
    @wb_version ||= metadata_sheet[*WBF[:meta_version_pos]]
  end

  delegate :sheet_count, :to => :book

  # this method return an array of column headers in raw data sheet.
  def headers
    header_info_lookup.keys
  end

  def headers_unique?
    headers.uniq_by(&:downcase).length == headers.length
  end

  # every column should have a header
  def with_missing_headers?
    columnnrs = header_info_lookup.values.collect do |info|
      info.is_a?(Array) ? info[0] : info
    end
    return true if columnnrs.empty?
    columnnrs.max + 1 > columnnrs.length
  end

  # The general metadata sheet contains information about the data set
  # as a whole.
  def general_metadata_hash
    {
      title: clean_string(metadata_sheet[*WBF[:meta_title_pos]]),
      abstract: clean_string(metadata_sheet[*WBF[:meta_abstract_pos]]),
      comment: clean_string(metadata_sheet[*WBF[:meta_comment_pos]]),
      usagerights: clean_string(metadata_sheet[*WBF[:meta_usagerights_pos]]),
      published: clean_string(metadata_sheet[*WBF[:meta_published_pos]]),
      spatialextent: clean_string(metadata_sheet[*WBF[:meta_spatial_extent_pos]]),
      temporalextent: clean_string(metadata_sheet[*WBF[:meta_temporalextent_pos]]),
      taxonomicextent: clean_string(metadata_sheet[*WBF[:meta_taxonomicextent_pos]]),
      design: clean_string(metadata_sheet[*WBF[:meta_design_pos]]),
      dataanalysis: clean_string(metadata_sheet[*WBF[:meta_dataanalysis_pos]]),
      circumstances: clean_string(metadata_sheet[*WBF[:meta_circumstances_pos]]),
      datemin: datemin,
      datemax: datemax
    }
  end

  # This method fetches authors from 15-17th rows in the metadata sheet.
  # A hash with two keys are returned: found_users and unfound_users
  def authors_list
    given_names = metadata_sheet.row(WBF[:meta_owners_start_row]).drop(1)
    surnames  = metadata_sheet.row(WBF[:meta_owners_start_row]+1).drop(1)
    # TODO: emails are not used right now.
    # TODO: store unfound_users into database
    # emails = metadata_sheet.row(WBF[:meta_owners_start_row]+2).drop(1)

    users = []
    given_names.zip(surnames) do |person|
      users << person unless person.all?(&:blank?)
    end
    find_users users
  end

  # Returns the tags that were in the respective cell.
  def projects_list
    projects = []
    project_string = metadata_sheet[*WBF[:meta_projects_pos]]

    return projects if project_string.blank?

    project_string.split(',').map(&:squish).uniq.each do |p|
      projects << Project.find_by_converting_to_tag(p) unless p.blank?
    end
    projects.compact
  end

  # this is the main workhorse that reads worksheets and import data into database
  def import_data
    return false unless @dataset
    save_data_columns
    import_categories
    add_acknowledged_people
    import_sheetcells
  end

private
  # Returns the object representing the general metadata sheet.
  def metadata_sheet
    @book.worksheet(WBF[:metadata_sheet])
  end

  # Returns the object representing the responsible people sheet.
  def data_responsible_person_sheet
    @book.worksheet(WBF[:people_sheet])
  end

  # Returns the object representing the 'columns and datagroups' sheet.
  def data_description_sheet
    @book.worksheet(WBF[:columns_sheet])
  end

  # This is the content of the 'columns and datagroups' sheet.
  def columns_info
    return @columns if defined? @columns
    @columns = []
    data_description_sheet.each(1) do |row|
      @columns << row.take(9).collect{|c| c.to_s.squish } unless row[0].blank?
    end
    return @columns
  end

  # Returns the object representing the categories sheet.
  def categories_sheet
    @book.worksheet(WBF[:category_sheet])
  end

  # Returns the object representing the raw data sheet.
  def raw_data_sheet
    @book.worksheet(WBF[:data_sheet])
  end

  # Helper method to determine the correct minimal date value from the string given in the Workbook.
  def datemin
    date_string = metadata_sheet[*WBF[:meta_datemin_pos]].to_s.strip
    Date.parse(date_string)
  rescue
    date_string.to_i > 2000 ? Date.new(date_string.to_i) : Date.today.beginning_of_year
  end

  # Helper method to determine the correct maximal date value from the string given in the Workbook.
  def datemax
    date_string = metadata_sheet[*WBF[:meta_datemax_pos]].to_s.strip
    Date.parse(date_string)
  rescue
    date_string.to_i > 2000 ? Date.new(date_string.to_i) : Date.today
  end

  # This generate a hash in form of {header: columnnr}. columnnr is 0-based.
  # When a column is saved later, its info will be stored into values.
  # then, this hash becomes {header: [columnnr, datacolumn_id, data_type_id]}
  def header_info_lookup
    @header_info_lookup ||= begin
      hash = Hash.new
      raw_data_sheet.row(0).each_with_index do |header, columnr|
        hash[header.squish] = columnr unless header.blank?
      end
      hash
    end
  end

  # This method saves columns into datacolumns table.
  # As a data column is saved into database, its info is recored
  # into @header_info_lookup
  def save_data_columns
    header_info_lookup.each do |header, columnnr|
      column_attr = columns_info.assoc(header)
      # if there is info for this column in the 'columns and datagroups' sheet
      if column_attr
        dc_hash = initialize_datacolumn(column_attr, columnnr)
        dc = Datacolumn.create!(dc_hash)
      else
        dc = Datacolumn.create!(columnheader: header, columnnr: columnnr + 1, dataset_id: @dataset.id)
      end

      @header_info_lookup[header] = [columnnr, dc.id, Datatypehelper.find_by_name(dc.import_data_type).id]
    end
  end

  def initialize_datacolumn(column_attr, columnnr)
    datagroup = fetch_or_create_datagroup(column_attr)

    column = {
      columnheader: column_attr[WBF[:column_header_col]],
      definition: column_attr[WBF[:column_definition_col]],
      columnnr: columnnr + 1,
      import_data_type: column_attr[WBF[:column_methodvaluetype_col]],
      unit: column_attr[WBF[:column_unit_col]],
      instrumentation: column_attr[WBF[:column_instrumentation_col]],
      informationsource: column_attr[WBF[:column_informationsource_col]],
      tag_list: column_attr[WBF[:column_keywords_col]],
      dataset_id: @dataset.id,
      datagroup_id: datagroup[:id]
    }

    if datagroup[:description_not_equal]
      # if the datagroup description is not exactly same with that on portal, then append it
      # to column's definition field.
      column[:definition] += "; Datagroup description: " + column_attr[WBF[:group_description_col]]
    end

    return column
  end

  # This method queries against existing datagroups on the portal.
  # If it doesn't exist, then create a new datagroup using the info
  # in the 'columns and datagroups' sheet.
  # The return value is a little strange. key :id represents the datagroup
  # id. When the datagroup description is not same with that existing on the
  # portal, a key :description_not_equal is also returned.
  def fetch_or_create_datagroup(column_attr)
    result = {id: nil}
    return result if column_attr[WBF[:group_title_col]].blank?

    dg_hash = {
      title: column_attr[WBF[:group_title_col]],
      description: column_attr[WBF[:group_description_col]],
    }

    datagroup = Datagroup.where(["title iLike ?", dg_hash[:title]]).first
    if datagroup
      result[:description_not_equal] = true if not_same?(datagroup.description, dg_hash[:description])
    else
      datagroup = Datagroup.create(dg_hash)
    end
    result[:id] = datagroup.id

    return result
  end

  # This method imports content in 'categories' sheet into import_categories table
  def import_categories
    fields = %w{short long description datacolumn_id}
    import_categories_in_queue = []
    counter = 0

    categories_sheet.each(1) do |row|
      row = row.take(4).collect {|c| convert_to_string(c) }

      header = row[WBF[:category_columnheader_col]]
      short = row[WBF[:category_short_col]]

      next unless @header_info_lookup[header] && !short.blank?

      long = row[WBF[:category_long_col]].blank? ? short : row[WBF[:category_long_col]]
      description = row[WBF[:category_description_col]].blank? ? long : row[WBF[:category_description_col]]

      import_categories_in_queue << [ short, long, description, @header_info_lookup[header][1] ]
      counter += 1

      # import categories in batch of about 1000.
      if counter >= 1000
        ImportCategory.import fields, import_categories_in_queue, :validate => false
        import_categories_in_queue.clear
        counter = 0
      end
    end
    ImportCategory.import fields, import_categories_in_queue, :validate => false
  end

  def add_acknowledged_people
    rows = []
    data_responsible_person_sheet.each(1) do |row|
      rows << row.take(3).collect {|c| c.try(:squish)} unless row[0].blank?
    end

    rows.group_by{|r| r[0].downcase }.each do |header, row|
      next unless @header_info_lookup[header]

      users = row.collect{|r| r.drop(1)}
      ppl = find_users(users)
      datacolumn = Datacolumn.find @header_info_lookup[header][1]
      ppl[:found_users].each do |user|
        user.has_role! :responsible, datacolumn
      end
      unless ppl[:unfound_usernames].blank?
        datacolumn.update_attribute :acknowledge_unknown, ppl[:unfound_usernames].join(', ')
      end
    end
  end

  # This method is the workhorse that imports raw data into sheetcells table.
  def import_sheetcells
    column_info_lookup = @header_info_lookup.values # a nested array [[columnr, column_id, datatype_id], ...]
    counter = 0
    sheetcells_in_queue = []

    1.upto(raw_data_sheet.row_count - 1).each do |rownr|
      raw_data_sheet.row(rownr).each_with_index do |cell, columnnr|
        cell = convert_to_string(cell)
        next if cell.blank? || !column_info_lookup.assoc(columnnr)  # Skip columns with blank headers

        sheetcells_in_queue << [column_info_lookup.assoc(columnnr)[1], cell, rownr+1, column_info_lookup.assoc(columnnr)[2]]
        counter += 1
      end

      if counter >= 1000
        save_data_into_database(sheetcells_in_queue, rownr)
        counter = 0
        sheetcells_in_queue.clear
      end
    end
    save_data_into_database(sheetcells_in_queue, raw_data_sheet.row_count-1)
  end

  def save_data_into_database(sheetcells, rownr)
    columns = [:datacolumn_id, :import_value, :row_number, :datatype_id]
    Sheetcell.import columns, sheetcells, :validate => false
    @dataset.update_attribute(:import_status, "Imported #{rownr} of #{raw_data_sheet.row_count-1} rows")
  end

  # gives found and unfound users
  # usernames must be an array af the formm [[firstname_1, lastname_1], [firstname_2, lastname_2]]
  def find_users(usernames = [])
    result = {found_users: [], unfound_usernames: []}

    usernames.each do |un|
      first = clean_string(un[0])
      last = clean_string(un[1])
      unless first.blank? && last.blank?
        u = User.where(['firstname iLike :first AND lastname iLike :last', first: first, last: last]).first
        if u
          result[:found_users] << u
        else
          result[:unfound_usernames] << "#{first} #{last}"
        end
      end
    end
    result.each {|k, v| v.uniq! }

    return result
  end

  # this method is used to process values in raw data sheet and categories sheet.
  # consecutive spaces are replaced by a single space. this is sensible for values
  # in these two sheets.
  def convert_to_string(input)
    return input if input.nil?

    if input.class == Spreadsheet::Formula
      input = input.value.is_a?(Spreadsheet::Excel::Error) ? "< Error in Excel Formula >" : input.value
    end
    # Excel sometimes appends a decimal digit to integer values, here we try to trim it off.
    return input.to_s.sub(/\.0$/,'') if input.is_a? Numeric

    input.to_s.squish
  end

  # clean_string removes any leading and trailing spaces from the input
  def clean_string(input)
    return input if input.nil?
    input.to_s.try(:strip)
  end

  def not_same?(datagroup_string, test_string)
    # blank test_string represents that it uses the info on the portal.
    # this allows users to omit datagroup description to avoid unconscious typo.
    return false if test_string.blank?
    return datagroup_string.squish.downcase != test_string.squish.downcase
  end
end
