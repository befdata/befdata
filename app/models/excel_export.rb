require "dataworkbook_format"

class ExcelExport
  include DataworkbookFormat

  def initialize(dataset)
    Spreadsheet.client_encoding = 'UTF-8'
    excel_workbook = Spreadsheet.open Rails.root.join('files', 'template','befdata_workbook_empty.xls')

    create_metasheet(excel_workbook, dataset)
    create_columnsheet(excel_workbook, dataset)
    create_peoplesheet(excel_workbook, dataset)
    create_categorysheet(excel_workbook, dataset)
    create_datasheet(excel_workbook, dataset)

    @data_buffer = StringIO.new
    workaround_for_readable_xls(excel_workbook)
    excel_workbook.write(@data_buffer)
  end

  def data_buffer
    return @data_buffer.string
  end

private

  def workaround_for_readable_xls(excel_workbook)
    # there needs to be some modification on every worksheet
    # otherwise multi-sheet spreadsheets won't be readable
    excel_workbook.worksheets.each do |ws|
      x = ws[0,0]
      ws[0,0] = x
    end
  end

  def create_metasheet (book, dataset)
    sheet = book.worksheet WBF[:metadata_sheet]

    sheet[*WBF[:meta_version_pos]] = WBF[:wb_format_version]

    sheet[*WBF[:meta_title_pos]] = dataset.title ||= ""
    sheet[*WBF[:meta_abstract_pos]] = dataset.abstract ||= ""
    sheet[*WBF[:meta_comment_pos]] = dataset.comment ||= ""
    sheet[*WBF[:meta_usagerights_pos]] = dataset.usagerights ||= ""
    sheet[*WBF[:meta_published_pos]] = dataset.published ||= ""
    sheet[*WBF[:meta_spatial_extent_pos]] = dataset.spatialextent ||= ""
    sheet[*WBF[:meta_temporalextent_pos]] = dataset.temporalextent ||= ""
    sheet[*WBF[:meta_taxonomicextent_pos]] = dataset.taxonomicextent ||= ""
    sheet[*WBF[:meta_design_pos]] = dataset.design ||= ""
    sheet[*WBF[:meta_dataanalysis_pos]] = dataset.dataanalysis ||= ""
    sheet[*WBF[:meta_circumstances_pos]] = dataset.circumstances ||= ""

    sheet[*WBF[:meta_datemin_pos]] = dataset.datemin ? dataset.datemin.to_date.to_s : ""
    sheet[*WBF[:meta_datemax_pos]] = dataset.datemax ? dataset.datemax.to_date.to_s : ""
    sheet[*WBF[:meta_projects_pos]] = dataset.projects.uniq.collect{|p| p.shortname}.sort.join(', ')

    c_owners = dataset.users.select{|p| p.has_role?(:owner, dataset)}
    unless c_owners.blank?
      i = WBF[:meta_owners_start_col]
      c_owners.each do |cpr|
        sheet[WBF[:meta_owners_start_row],i] = cpr.firstname ||= ""
        sheet[WBF[:meta_owners_start_row]+1,i] = cpr.lastname ||= ""
        sheet[WBF[:meta_owners_start_row]+2,i] = cpr.email
        i += 1
      end
    end
  end

  def create_columnsheet (book, dataset, column_selection = nil)
    sheet = book.worksheet WBF[:columns_sheet]
    datacolumns = query_datacolumns(dataset, column_selection)

    row = 0
    datacolumns.each do |datacolumn|
      if column_selection
        row += 1
      else
        row = datacolumn.columnnr
      end
      sheet[row,WBF[:column_header_col]] = datacolumn.columnheader if datacolumn.columnheader
      sheet[row,WBF[:column_definition_col]] = datacolumn.definition if datacolumn.definition
      sheet[row,WBF[:column_unit_col]] = datacolumn.unit if datacolumn.unit

      keywords = datacolumn.tag_list.join(", ")
      sheet[row,WBF[:column_keywords_col]] = keywords unless keywords.blank?

      sheet[row,WBF[:group_title_col]] = datacolumn.datagroup.title if datacolumn.datagroup.title
      sheet[row,WBF[:group_description_col]] = datacolumn.datagroup.description if datacolumn.datagroup.description
      sheet[row,WBF[:group_methodvaluetype_col]] = datacolumn.datagroup.methodvaluetype if datacolumn.datagroup.methodvaluetype

      instrumentation = datacolumn.instrumentation || datacolumn.datagroup.instrumentation
      instrumentation << " (derived from datagroup)" if !datacolumn.instrumentation && !instrumentation.blank?
      sheet[row,WBF[:group_instrumentation_col]] = instrumentation

      informationsource = datacolumn.informationsource || datacolumn.datagroup.informationsource
      informationsource << " (derived from datagroup)" if !datacolumn.informationsource && !informationsource.blank?
      sheet[row,WBF[:group_informationsource_col]] = informationsource
    end
  end

  def create_peoplesheet (book, dataset, column_selection = nil)
    sheet = book.worksheet WBF[:people_sheet]
    datacolumns = query_datacolumns(dataset, column_selection)

    row = 1
    datacolumns.each do |datacolumn|
      datacolumn.users.each do |pr|
        sheet[row,WBF[:people_columnheader_col]] = datacolumn.columnheader if datacolumn.columnheader
        sheet[row,WBF[:people_firstname_col]] = pr.firstname if pr.firstname
        sheet[row,WBF[:people_lastname_col]] = pr.lastname if pr.lastname
        row += 1
      end
    end
  end

  def create_categorysheet(book, dataset, column_selection = nil)
    sheet = book.worksheet WBF[:category_sheet]
    datacolumns = query_datacolumns(dataset, column_selection)

    approved_cols = datacolumns.select{|c| c.datatype_approved?}

    row = 1
    approved_cols.each do |col|
      cats = col.sheetcells.select{|s| s.datatype.is_category?}.collect{|s| s.category}
      clean_cats = cats.compact.uniq.sort{|a,b| a.short <=> b.short}
      clean_cats.each do |cat|
        sheet[row,WBF[:category_columnheader_col]] = col.columnheader
        sheet[row,WBF[:category_short_col]] = cat.short
        sheet[row,WBF[:category_long_col]] = cat.long
        sheet[row,WBF[:category_description_col]] = cat.description
        row += 1
      end

      download_time = Time.now.to_s
      unaccepted_values = col.sheetcells.select{|s| s.accepted_value.blank? && !s.datatype.is_category?}.collect{|s| s.import_value}
      clean_un_val = unaccepted_values.compact.uniq.sort
      clean_un_val.each do |uv|
        sheet.row(row).default_format = WBF[:unapproved_format]
        sheet[row,WBF[:category_columnheader_col]] = col.columnheader
        sheet[row,WBF[:category_short_col]] = uv
        sheet[row,WBF[:category_long_col]] = uv
        sheet[row,WBF[:category_description_col]] = "#{uv}: automatically added during validation (#{download_time})"
        row += 1
      end
    end
  end

  def create_datasheet (book, dataset, column_selection = nil)
    sheet = book.worksheet WBF[:data_sheet]

    datacolumns = query_datacolumns(dataset, column_selection)

    col = 0
    datacolumns.each do |datacolumn|
      if column_selection
        col += 1 #render from beginning
      else
        col = datacolumn.columnnr #use original col number
      end

      sheet[0,col-1] = datacolumn.columnheader if datacolumn.columnheader

      datacolumn.sheetcells.each do |sheetcell|
        if sheetcell.datatype.is_category? && sheetcell.category
          value = sheetcell.category.short
        elsif sheetcell.datatype.name.match(/^date/) && sheetcell.accepted_value
          value = sheetcell.accepted_value.to_date.to_s
        elsif sheetcell.accepted_value
          value = sheetcell.accepted_value
        else
          value = sheetcell.import_value
          sheet.row(sheetcell.row_number - 1).set_format(col - 1, WBF[:unapproved_format])
        end
        sheet[sheetcell.row_number - 1, col - 1] = value if value
      end
    end
  end

  def query_datacolumns(dataset = nil, column_selection = nil)
    if column_selection
      column_selection
    else
      Datacolumn.all(:conditions => ["dataset_id = ?", dataset.id], :order => "columnnr ASC").uniq
    end
  end
end