# This file controlls the import of an BEF-China workbook into the
# data portal.  It opens the file uploaded to the data portal and
# stores it's values in the data base.  It then goes through data and
# metadata interactively to verify the correctness of the data.  For
# opening the workbook we currently rely on the ruby-package
# "spreadsheet".  This has to be changed here to adapt to other
# formats such as Open Office or .xlsx files.

class ImportsController < ApplicationController
  before_filter :load_freeformats_dataset, :only => [:update_dataset_freeformat_file]

  skip_before_filter :deny_access_to_all
  access_control do
    #TODO this has to be specified see #
    allow logged_in

    action :update_dataset_freeformat_file do
      allow :owner, :of => :freeformats_dataset
    end
  end

  def create_dataset_freeformat
    freeformat = Freeformat.new(params[:freeformat])

    if freeformat.save
      redirect_to :controller => :datasets, :action => :upload_dataset_freeformat, :freeformat_id => freeformat.id
    else
      flash[:errors] = freeformat.errors
      redirect_to :back
    end
  end

  def update_dataset_freeformat_file
    freeformat = Freeformat.find(params[:freeformat][:id])
    freeformat.file = params[:freeformat][:file]
    if freeformat.save
      redirect_to :controller => :datasets, :action => :show, :id => freeformat.dataset.id
    else
      flash[:errors] = freeformat.errors
      redirect_to :back
    end
  
  end

  def raw_data_overview
    @dataset ||= Dataset.find(params[:dataset_id], :include => [:datacolumns])

    load_workbook

    # Are there data columns already associated to this Dataset?
    return unless @book.columnheaders_unique? # we can only go on, if columnheaders of data columns are unique

    if @dataset.datacolumns.length == 0
      @just_uploaded = true
      Dataworkbook.delay.import_data(@dataset.id)
    else
    end
  end # raw data overview

  # After the general metadata of a data set has been saved to a
  # Context in the ContextsController and after the cell entries in
  # the raw data sheet have been saved in Measurement instances
  # (raw_data_overview), this method manages provenance information as
  # well as data checking and allocation to value tables
  # (Numericvalue, Categoricvalue, etc).
  def raw_data_per_header
    @dataset ||= Dataset.find(params[:dataset_id], :include => [:datacolumns, :upload_spreadsheet])
    @data_column ||= @dataset.datacolumns.select{|dc| dc.columnheader == params[:data_header]}.first

    load_workbook

    # data column specific information: start with the column header
    columnheader = @data_column.columnheader

    data_group_title = @book.method_index_for_columnheader(columnheader).blank? ? columnheader : @book.data_group_title(columnheader)
    @data_groups_available = Datagroup.find_similar_by_title(data_group_title)

    # collect all methods for the select button
    @methods_short_list = Datagroup.find(:all, :order => "title").collect{|m| [m.title, m.id]}

    # prepare a new data group instance to save it if needed
    @data_group_new = Datagroup.new(@book.methodsheet_datagroup(columnheader))

    # list of all Person Roles, sorted
    @people_list = User.find(:all, :order => :lastname)

    # Are there already people associated?
    @ppl = @data_column.users

    # Only look into the spreadsheet, if there are no people linked.
    if @ppl.blank?
      ppl = @book.lookup_data_header_people(columnheader)
      ppl = ppl.flatten.uniq
      ppl.each do |user|
        user.has_role! :responsible, @data_column
      end
      @ppl = @data_column.users
    end

    # returns a data hash with rownr => data entry from the
    # spreadsheet !Zeitschlucker?!
    #@cell_values_all = @data_column.rownr_entry_hash
    #logger.debug @cell_values_all.inspect

    # collect all categories for this data column; Array of Categories
    @portal_cats = @data_column.datagroup.datacell_categories_sql

    # collect all categories provided in the category sheet and
    # present them, no matter if they are double or not.  Do this only
    # if no import categories are provided yet
    if @data_column.import_categoricvalues.blank?
      sheet_cats_hash_array = look_for_provided_cats(columnheader, @book.data_categories_sheet, @dataset.title)

      # !! the problem here is that cat_info has to have entries in all short, long,
      # and description to be properly saved
      sheet_new_cats = sheet_cats_hash_array.map{|cat_info| Category.create(cat_info)}

      sheet_new_imp_cats = sheet_new_cats.map{|cat| ImportCategoricvalue.new(:category => cat)}

      @data_column.import_categoricvalues = sheet_new_imp_cats
    end

    @sheet_cats = @data_column.import_categoricvalues.map{|imp_c| [imp_c.category.id, imp_c.category.short, imp_c.category.long]}
  end

  def update_data_header
    data_header = Datacolumn.find(params[:datacolumn][:id])

    if data_header.update_attributes(params[:datacolumn])
      redirect_to :back
    else
      redirect_to data_path
    end
  end

  def update_data_group
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
        else
          flash[:notice] = data_group.errors
          redirect_to :back
        end
      end
    rescue ActiveRecord::RecordInvalid => invalid
      redirect_to :root
    end
  end

  # Assingning provenance informaiton: linking people to a data column
  def update_people_for_data_header
    redirect_to :back and return if params[:people].blank?
    data_column = Datacolumn.find(params[:datacolumn][:id])
    people = User.find(params[:people])

    # assigning provenance information: linking people to a data
    # column
    people.each do |pr|
      pr.has_role! :responsible, data_column
    end
    redirect_to :back
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
    data_column = Datacolumn.find(params[:datacolumn][:id])
    data_column.update_attributes(params[:datacolumn])

    # Text values do not have associated categoric values (naming
    # conventions), all the others have.  This is because the
    # scientists wanted to have different options in describing
    # types of missing values.
    if data_column.import_data_type == "text"
      text_data_column_import(data_column.id)
    else
      logger.debug "------------ looking for naming conventions  ---------"
      portal_cats = data_column.datagroup.datacell_categories_sql
      sheet_cats = data_column.import_categoricvalues.map{|icat| icat.category}
      if data_column.import_data_type == "category"
        category_data_column_import(data_column.id, portal_cats, sheet_cats)
      elsif data_column.import_data_type == "number"
        numeric_data_column_import(data_column.id, portal_cats, sheet_cats)
      elsif data_column.import_data_type == "date(14.07.2009)"
        datetime_data_column_import(data_column.id, portal_cats, sheet_cats)
      elsif data_column.import_data_type == "date(2009-07-14)"
        datetime_data_column_import(data_column.id, portal_cats, sheet_cats)
      elsif data_column.import_data_type == "year"
        year_data_column_import(data_column.id, portal_cats, sheet_cats)
      end
    end

    # by now values have been added
    unless data_column.categories.blank?
      redirect_to(:controller => :imports,
      :action => :data_column_categories,
      :data_column_id => data_column.id)
    else
      redirect_to :back
    end
  end

  def data_column_categories
    @data_column = Datacolumn.find(params[:data_column_id])
    @dataset = @data_column.dataset
    portal_cats = @data_column.datagroup.datacell_categories_sql
    sheet_cats = @data_column.import_categoricvalues.map{|icat| icat.category}
    @cats_to_choose = [portal_cats + sheet_cats].flatten.uniq
    @cats_to_choose.sort!{|x,y| x.verbose <=> y.verbose}
    cells_with_cats = @data_column.sheetcells.select{|cell| cell.datatype.name == "category"}
    # Cells (Measurements) can be set to valid; categoric values can
    # be set to "manually approved".
    cells = cells_with_cats.
    select{|cell|  cell.comment == "invalid"}
    cell_unique_entries = cells.collect{|cell|  cell.import_value}.uniq.sort
    @cell_uniq_arr = []
    cell_unique_entries.each do |entry|
      @cell_uniq_arr << cells.select{|cell| cell.import_value == entry }[0]
    end
  end

  # Exports a Context for merging and correcting as .xls file.  Then
  # destroys this context and all its values.
  def context_export_destroy
    # export context is missing, should use the export from the
    # context controller

    # destroy context
    dataset = Dataset.find(params[:dataset_id])
    dataset.destroy

    # reset_session; this logs you out
    redirect_to root_path
  end

  def cell_category_create
    first_cell = Sheetcell.find(params[:sheetcell][:id])
    entry = first_cell.import_value
    same_entry_cells = first_cell.same_entry_cells

    # the new category; needs error handling
    cat = Category.new(params[:category])
    cat.comment = "manually approved"
    cat.long = entry if cat.long.blank?
    cat.description = cat.long if cat.description.blank?
    logger.debug "------------ after crating new category  ---------"
    logger.debug cat.inspect

    if cat.save
      same_entry_cells.each do |cell|
        old_cat = cell.category
        cell.update_attributes(:category => cat,
        :comment => "valid")
        old_cat.destroy # validates that it is not destroyed if
        # linked to measurement or import category
      end
      redirect_to :back
    else
      redirect_to data_path
    end
  end

  def cell_category_update
    first_cell = Sheetcell.find(params[:sheetcell][:id])
    logger.debug "- params[:measurement]  -"
    logger.debug params[:sheetecell].inspect
    first_cell.update_attributes(params[:sheetcell])
    same_entry_cells = first_cell.same_entry_cells
    logger.debug "- same_entry_cells  -"
    logger.debug same_entry_cells.inspect

    # category
    cat = first_cell.category
    cat.update_attributes(:comment => "manually approved")

    same_entry_cells.each do |cell|
      logger.debug "- old and new cell  -"
      logger.debug cell.inspect
      old_cat = cell.category
      cell.update_attributes(:category => cat,
      :comment => "valid")
      old_cat.destroy
    end

    # !! validations !!
    redirect_to :back
  end

  def dataset_freeformat_overview

    @dataset = Dataset.find(params[:dataset_id])

    if @dataset
      # nothing to be done
    else
      # really should tell them about the error
      redirect_to data_path and return
    end

  end

  def save_dataset_freeformat_tags

    @dataset = Dataset.find(params[:dataset][:id])
    @dataset.update_attributes(params[:dataset])

    redirect_to url_for(:controller => :datasets,
    :action => :show,
    :id => @dataset.id) and return
  end

  private

  def load_workbook
    @book = Dataworkbook.new(@dataset.upload_spreadsheet)
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
        elsif object.length == 1# if it is only 0, then it should be a number also
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
  def look_for_provided_cats(columnheader, categorysheet, dataset_title)
    logger.debug "## acronym and descriptions provided"
    logger.debug columnheader.inspect
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
          comment = 'added from category sheet in dataset: ' + dataset_title
          provided_hash = {:short => short,
            :long => prov_long[i0],
            :description => prov_description[i0],
            :comment => comment}
          logger.debug "provided_hash.inspect"
          logger.debug provided_hash.inspect
          provided_hash_array << provided_hash
        end
      end
    end
    return provided_hash_array
  end

  # Category specific routine to import values (Categoricvalue).
  # Takes the id of the Data Column (MeasuremntsMethodstep),
  # categories available for the Data Group (Methodstep), and the
  # categories provided in the Data Sheet (provide_metasheets).
  # Creates a Categoricvalue for each Entry in the Data Sheet
  # (Measurement).  No output generated.  Is called by
  # add_data_values.
  def category_data_column_import(data_column_id, portal_cats, sheet_cats)
    data_column = Datacolumn.find(data_column_id, :include => :sheetcells)

    # the entries themselves
    cells = data_column.sheetcells

    # Check each entry loop; recheckes if values have already been
    # given
    cells.each do |cell|
      entry = cell.import_value
      obs = cell.observation

      comment_cat_hash = suggest_category_for_entry(portal_cats, sheet_cats, entry)
      cat = comment_cat_hash[:cat]
      cell_comment = comment_cat_hash[:cell_comment]

      cell.comment = cell_comment

      if cell_comment == "invalid"
        cat = Category.create(:short => entry,
        :long => entry,
        :description => entry,
        :comment => "automatically generated")
      end

      old_val = cell.category
      cell.category = cat
      cell.save
      old_val.destroy if old_val
      logger.debug "- cell.save  -"
      logger.debug cell.inspect
    end # Entry loop

  end

  def numeric_data_column_import(data_column_id, portal_cats, sheet_cats)
    data_column = Datacolumn.find(data_column_id, :include => :sheetcells)

    cells = data_column.sheetcells

    # Check each entry loop
    cells.each do |cell|
      entry = cell.import_value
      obs = cell.observation

      comment_cat_hash = suggest_category_for_entry(portal_cats, sheet_cats, entry)

      # invalid if not categoricvalue is found
      cell_comment = comment_cat_hash[:cell_comment]

      if cell_comment != "invalid"
        cell.category = comment_cat_hash[:cat]
      elsif numeric?(entry)
        cell.accepted_value = entry
        cell_comment = "valid"
      else
        value = Category.create(:short => entry,
        :long => entry,
        :description => entry,
        :comment => "automatically generated")
        cell.category = value
      end

      cell.comment = cell_comment
      cell.save
    end # Entry loop
  end

  def text_data_column_import(data_column_id)
    data_column = Datacolumn.find(data_column_id, :include => :sheetcells)

    # the entries themselves
    cells = data_column.sheetcells

    # Check each entry loop
    cells.each do |cell|
      entry = cell.import_value
      obs = cell.observation

      # here could one place custom validation
      if true
        cell.accepted_value = entry
        cell_comment = "valid"
      else
        # validation error
      end

      cell.comment = cell_comment
      cell.save
      logger.debug "------------ after saving cell.save  ---------"
      logger.debug cell.inspect
    end # Data column entries loop
  end

  def datetime_data_column_import(data_column_id, portal_cats, sheet_cats)
    data_column = Datacolumn.find(data_column_id, :include => :sheetcells)
    date_format =
    case data_column.import_data_type
    when "date(14.07.2009)" then '%d.%m.%Y'
    when "date(2009-07-14)" then '%Y-%m-%d'
    end

    cells = data_column.sheetcells

    # Check each entry loop
    cells.each do |cell|
      entry = cell.import_value
      obs = cell.observation

      comment_cat_hash = suggest_category_for_entry(portal_cats, sheet_cats, entry)

      # invalid if not categoricvalue is found
      cell_comment = comment_cat_hash[:cell_comment]

      if cell_comment != "invalid"
        cell.category = comment_cat_hash[:cat]
      else
        begin
          entry = Date.strptime(entry, date_format)

          cell.accepted_value = entry.to_s
          cell_comment = "valid"
        rescue
          value = Category.create(:short => entry,
          :long => entry,
          :description => entry,
          :comment => "automatically generated")
          cell.category = value
        end
      end

      cell.comment = cell_comment
      cell.save
    end # Entry loop
  end

  def year_data_column_import(data_column_id, portal_cats, sheet_cats)
    data_column = Datacolumn.find(data_column_id, :include => [:sheetcells])

    cells = data_column.sheetcells

    # Check each entry loop
    cells.each do |cell|
      entry = cell.import_value
      obs = cell.observation

      comment_cat_hash = suggest_category_for_entry(portal_cats, sheet_cats, entry)
      cell_comment = comment_cat_hash[:cell_comment]

      if cell_comment != "invalid"
        cell.category = comment_cat_hash[:cat]
      elsif integer?(entry)
        entry = entry.to_i.to_s
        cell.accepted_value= entry
        cell_comment = "valid"
      else
        value = Category.create(:short => entry,
        :long => entry,
        :description => entry,
        :comment => "automatically generated")
        cell.category = value
      end

      cell.comment = cell_comment
      cell.save
    end # Entry loop
  end

  # Checking categories for exact matches, first on the portal, then
  # in the spreadsheet.  Returns a hash with the cell_comment,
  # stating: "portal match", "sheet match", "invalid".  The hash also
  # contains the Categoricvalue if found.
  def suggest_category_for_entry(portal_cats, sheet_cats, entry)
    cat_found = nil
    entry = entry.to_i.to_s if integer?(entry)

    cat = find_entry_in_cat_array(portal_cats, entry)
    logger.debug "------------ cat after portal match  ----------"
    logger.debug cat.inspect
    unless cat.blank?
      cell_comment = "portal match"
    else
      cat = find_entry_in_cat_array(sheet_cats, entry)
      logger.debug "------------ cat after sheet match  ----------"
      logger.debug cat.inspect
      unless cat.blank?
        cell_comment = "sheet match"
      else
        # in come the "find similar" routines; these can give numbers
        # of increasing dissimilarity, so that the lowest number is
        # identical, for example
      end
    end

    if cat.nil?
      cell_comment = "invalid"
    end

    return {:cell_comment => cell_comment,
      :cat => cat}
  end

  def find_entry_in_cat_array(cat_array, entry)
    # Is there a match?  Short or long.  Note in Measurement
    # .upload_info: portal match
    logger.debug "------------ entering find_entry_in_cat_array  -----------"
    logger.debug "------------ entry  --------------------"
    logger.debug entry
    logger.debug "------------ cat_array  --------------------"
    logger.debug cat_array.inspect
    matches = cat_array.select{|c| c.short == entry}
    logger.debug "------------ matches short  --------------------"
    logger.debug matches.inspect
    if matches.blank?
      matches = cat_array.select{|c| c.long == entry}
      logger.debug "------------ matches long  --------------------"
      logger.debug matches.inspect
      if matches.blank?
        cat = nil
      else # matching categoricvalue.long
        cat = matches[0]
      end
    else # matching categoricvalue.short
      cat = matches[0]
    end
    logger.debug "------------ cat  --------------------"
    logger.debug cat.inspect
    logger.debug "------------ leaving find_entry_in_cat_array  --------------------"
    return cat
  end

  def load_freeformats_dataset
    @freeformats_dataset = Freeformat.find(params[:freeformat][:id]).dataset
  end

end
