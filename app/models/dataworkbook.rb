class Dataworkbook
  def initialize(datafile, book)
    # Open the file and read its content
    @book = book
    @datafile = datafile
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

  def general_metadata_sheet
    @book.worksheet(0)
  end

  def data_description_sheet # former methodsheet
    @book.worksheet(1)
  end

  def data_responsible_person_sheet
    @book.worksheet(2)
  end

  def data_categories_sheet
    @book.worksheet(3)
  end

  def raw_data_sheet
    @book.worksheet(4)
  end

  def general_metadata_column
    Array(general_metadata_sheet.column(0))
  end

  def columnheaders_raw
    Array(raw_data_sheet.row(0)).compact
  end

  def columnheaders_unique?
    columnheaders_raw.length == columnheaders_raw.uniq.length
  end

  def people_names_hash
    # Determine number of people
    n = Array(general_metadata_sheet.row(14)).length - 1 # The first column contains only meta data

    # Gather the people
    users = []
    n.times do |i|
      users << {:firstname => Array(general_metadata_sheet.column(i+1))[14], :lastname => Array(general_metadata_sheet.column(i+1))[15]}
    end

    return users
  end

  def tag_list
    Array(general_metadata_sheet.column(1))[11]
  end

  def datemin
    value = general_metadata_column[32].to_s
    begin
      date = Date.parse(value)
    rescue ArgumentError
      year = date.to_i > 2000 ? data.to_i : Date.today.year
      date = Date.new(year, 1, 1)
    end
    return date
  end

  def datemax
    value = general_metadata_column[34].to_s
    begin
      date = Date.parse(value)
    rescue ArgumentError
      year = date.to_i > 2000 ? data.to_i : Date.today.year
      date = Date.new(year, 12, 31)
    end
    return date
  end

  def data_column_info_for_columnheader(columnheader)
    method_index = Array(data_description_sheet.column(0)).index(columnheader)

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
end
