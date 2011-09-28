class ExcelExport


  def initialize(dataset)

    Spreadsheet.client_encoding = 'UTF-8'
    excel_workbook = Spreadsheet::Workbook.new

    spreadsheet_formatting = {}
    spreadsheet_formatting[:dataformat] = Spreadsheet::Format.new :size => 11, :horizontal_align => :left, :italic => true
    spreadsheet_formatting[:metaformat] = Spreadsheet::Format.new :size => 11, :horizontal_align => :left, :color => 'brown'
    spreadsheet_formatting[:unapprovedformat] = Spreadsheet::Format.new :size => 11, :horizontal_align => :left, :color => 'grey'

    create_metasheet(excel_workbook, dataset, spreadsheet_formatting)
    create_methodsheet(excel_workbook, dataset, spreadsheet_formatting)
    create_peoplesheet(excel_workbook, dataset, spreadsheet_formatting)
    create_categorysheet(excel_workbook, dataset, spreadsheet_formatting)
    create_datasheet(excel_workbook, dataset, spreadsheet_formatting)

    @data_buffer = StringIO.new
    excel_workbook.write(@data_buffer)
    
  end

  def data_buffer
    return @data_buffer.string
  end

  # Creates the first sheet of a context file, the one with the
  # metadata.
  def create_metasheet (book, dataset, formats)
    # This action canot be called externally.
    sheet = book.create_worksheet :name => 'General Metadata'

    sheet.column(0).width = 80

    [0, 2, 5, 8].each{|n| sheet.row(n).set_format(0, formats[:metaformat])}
    sheet[0,0] = I18n.t('metadata.head')
    sheet[2,0] = I18n.t('metadata.title')
    sheet.row(3).set_format(0, formats[:dataformat])
    sheet[3,0] = dataset.title ||= ""

    sheet[5,0] = I18n.t('metadata.abstract')
    sheet[6,0] = dataset.abstract ||= ""
    sheet.row(6).set_format(0, formats[:dataformat])

    sheet[8,0] = I18n.t('metadata.comments')
    sheet[9,0] = dataset.comment ||= ""
    sheet.row(9).set_format(0, formats[:dataformat])

    (11..18).each{|n| sheet.row(n).set_format(0, formats[:metaformat])}
    sheet[11,0] = I18n.t('metadata.project')
    sheet[11,1] = dataset.projects.uniq.collect{|p| p.shortname}.sort.join(', ')

    sheet[13,0] = I18n.t('metadata.people')
    sheet[14,0] = I18n.t('metadata.givenname')
    sheet[15,0] = I18n.t('metadata.surname')
    sheet[16,0] = I18n.t('metadata.email')

    c_owners = dataset.users.select{|p| p.has_role?(:owner, dataset)}
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
        sheet[16,i] = cpr.email
        # end
        # sheet[18,i] = cprpr.role.name ||= ""
        i += 1
      end
    end

    [21, 23, 26, 27, 30, 31, 33, 35, 38, 41, 44, 47].each{|n| sheet.row(n).set_format(0, formats[:metaformat])}
    sheet[21,0] = I18n.t('metadata.usagerights')
    sheet[22,0] = dataset.usagerights ||= ""
    sheet.row(22).set_format(0, formats[:dataformat])

    sheet[23,0] = I18n.t('metadata.published')
    sheet[24,0] = dataset.published ||= ""
    sheet.row(24).set_format(0, formats[:dataformat])

    sheet[26,0] = I18n.t('metadata.methods')
    sheet[27,0] = I18n.t('metadata.spatialextent')
    sheet[28,0] = dataset.spatialextent ||= ""
    sheet.row(28).set_format(0, formats[:dataformat])

    sheet[30,0] = I18n.t('metadata.temporalextent')
    sheet[31,0] = I18n.t('metadata.datemin')
    sheet[32,0] = dataset.datemin ? dataset.datemin.to_date.to_s : ""
    sheet.row(32).set_format(0, formats[:dataformat])

    sheet[33,0] = I18n.t('metadata.datemax')
    sheet[34,0] = dataset.datemax ? dataset.datemax.to_date.to_s : ""
    sheet.row(34).set_format(0, formats[:dataformat])

    sheet[35,0] = I18n.t('metadata.datedescription')
    sheet[36,0] = dataset.temporalextent ||= ""
    sheet.row(36).set_format(0, formats[:dataformat])

    sheet[38,0] = I18n.t('metadata.taxonomicextent')
    sheet[39,0] = dataset.taxonomicextent ||= ""
    sheet.row(39).set_format(0, formats[:dataformat])

    sheet[41,0] = I18n.t('metadata.design')
    sheet[42,0] = dataset.design ||= ""
    sheet.row(42).set_format(0, formats[:dataformat])

    sheet[44,0] = I18n.t('metadata.dataanalysis')
    sheet[45,0] = dataset.dataanalysis ||= ""
    sheet.row(45).set_format(0, formats[:dataformat])

    sheet[47,0] = I18n.t('metadata.circumstances')
    sheet[48,0] = dataset.circumstances ||= ""
    sheet.row(48).set_format(0, formats[:dataformat])

    return nil
  end

  # Creates the second sheet of a context file, the one with the
  # method descriptions.  If no methods are given, all methods of the
  # context will be used.
  def create_methodsheet (book, dataset, formats, methods = nil)
    # This action canot be called externally.

    #Create the sheet and fill in the headers
    sheet = book.create_worksheet :name => 'Column description'

    sheet.row(0).default_format = formats[:metaformat]
    sheet.row(0).height = 120

    sheet[0,0] = "Column header"
    sheet[0,1] = "Definition"
    sheet[0,2] = "Unit of measurement"
    sheet[0,3] = "Missing value code"
    sheet[0,4] = "Coma separated keywords"
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
      mms = Datacolumn.find(:all, :conditions => ["dataset_id = ?", dataset.id], :order => "columnnr ASC")
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

      sheet[row,5] = datacolumn.datagroup.title if datacolumn.datagroup.title
      sheet[row,6] = datacolumn.datagroup.description if datacolumn.datagroup.description
      sheet[row,7] = datacolumn.datagroup.instrumentation if datacolumn.datagroup.instrumentation
      sheet[row,8] = datacolumn.datagroup.informationsource if datacolumn.datagroup.informationsource
      sheet[row,9] = datacolumn.datagroup.methodvaluetype if datacolumn.datagroup.methodvaluetype
      sheet[row,10] = datacolumn.datagroup.timelatency if datacolumn.datagroup.timelatency
      sheet[row,11] = datacolumn.datagroup.timelatencyunit if datacolumn.datagroup.timelatencyunit
    end
  end

  # Creates the third sheet of a context file, the one with the people
  # involved.  If no Method are given, all people of the context will
  # be listed.
  def create_peoplesheet (book, dataset, formats, methods = nil)
    # This action canot be called externally.

    sheet = book.create_worksheet :name => 'Members involved'

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
      mms = Datacolumn.find(:all, :conditions => ["dataset_id = ?", dataset.id], :order => "columnnr ASC")
    end

    row = 1
    mms.each do |step|
      step.users.each do |pr|
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
  # the categoric descriptions.  If no Columns  are given, all
  # appropriate categories of the context will be listed.
  # Note: Columns were earlier called methods
  def create_categorysheet(book, dataset, formats, columns = nil)
    # This action canot be called externally.

    sheet = book.create_worksheet :name => 'column categories'

    sheet.row(0).default_format = formats[:metaformat]
    sheet.row(0).height = 120
    sheet[0,0] = "Column header"
    sheet[0,1] = "Category short"
    sheet[0,2] = "Category long"
    sheet[0,3] = "Category description"

    if columns
      cols = columns
    else
      cols = Datacolumn.find(:all, :conditions => ["dataset_id = ?", dataset.id], :order => "columnnr ASC")
    end

    approved_cols = cols.select{|c| c.datatype_approved?}

    row = 1

    approved_cols.each do |col|
      cats = []
      col.sheetcells.select{|s| s.datatype.is_category?}.each{|s| cats << s.category}
      clean_cats = cats.compact.uniq.sort{|a,b| a.short <=> b.short}
      clean_cats.each do |cat|
        sheet.row(row).default_format = formats[:dataformat]
        sheet[row,0] = col.columnheader
        sheet[row,1] = cat.short
        sheet[row,2] = cat.long
        sheet[row,3] = cat.description
        row += 1
      end
    end
  end


  # Creates the last sheet of a context file, the one that contains the raw data.
  # If no Method are given, all people of the context will be listed.
  def create_datasheet (book, dataset, formats, columns = nil)
    # This action canot be called externally.

    sheet = book.create_worksheet :name => 'Raw data'
    sheet.row(0).default_format = formats[:metaformat]

    if columns
      datacols = columns
    else
      datacols = Datacolumn.find(:all, :conditions => ["dataset_id = ?", dataset.id], :order => "columnnr ASC").uniq
    end

    column = 0
    datacols.each do |datacolumn|
      if columns
        # If only some columns are rendered, each Column is rendered from the beginning of the page
        column += 1
      else
        # Otherwise, if all columns are used, we can take the original columnnr
        column = datacolumn.columnnr
      end

      # Columnheader comes first
      sheet[0,column-1] = datacolumn.columnheader if datacolumn.columnheader

      # Go throuch each sheetcell of the columns
      datacolumn.sheetcells.each do |sheetcell|
        if sheetcell.datatype.is_category? && sheetcell.category
          value = sheetcell.category.short
        elsif sheetcell.datatype.name.match(/^date/) && sheetcell.accepted_value
          value = sheetcell.accepted_value.to_date.to_s
        elsif sheetcell.accepted_value
          value = sheetcell.accepted_value
        else
          value = sheetcell.import_value
          sheet.row(sheetcell.row_number - 1).set_format(column - 1, formats[:unapprovedformat])
        end
        sheet[sheetcell.row_number - 1, column - 1] = value if value
      end
    end
  end

end