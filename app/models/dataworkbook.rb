class Dataworkbook
  def initialize(datafile, book)
    # Open the file and read its content
    @book = book.dup
    @datafile = datafile.dup
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

  def general_metadata_column
    Array(general_metadata_sheet.column(0))
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
end
