require 'test_helper'

class ImportTest < ActiveSupport::TestCase
self.use_transactional_fixtures = false

  test "upload_import_and_approve_dataset" do
    #========Upload a workbook============#
    datafile = Datafile.create(:file => File.new(File.join(fixture_path, 'test_files_for_uploads',
                                                           'UnitTestSpreadsheetForUpload_new.xls')))
    assert_true datafile.save, datafile.errors

    dataset = Dataset.create(:title => "just4testing")
    dataset.current_datafile = datafile

    assert_true dataset.save, dataset.errors

    #========import dataset============#
    book = Workbook.new(dataset.current_datafile)
    book.import_data

    #======= the first number column: number1 ============#
    column_number1 = dataset.datacolumns.where(columnnr: 2).first

    assert_not_nil column_number1
    assert_equal 'number1', column_number1.columnheader
    assert_equal 'number', column_number1.import_data_type
    assert_equal 'data group - elevation', column_number1.datagroup.title
    assert_equal 27, column_number1.sheetcells.count, "column number1 does not have 27 values inported"
    assert_equal '522', column_number1.sheetcells.where(row_number: 2).first.import_value
    assert_equal 'NA', column_number1.sheetcells.where(row_number: 28).first.import_value

    #======= the first category column: category =========#
    column_category = dataset.datacolumns.where(columnnr: 5).first

    assert_not_nil column_category
    assert_equal 'category', column_category.columnheader
    assert_equal 'category', column_category.import_data_type

    importcats = column_category.import_categories
    assert_equal 7, importcats.count

    importcats.each do |cat|
      # only a short value was provided
      assert(cat.short==cat.long && cat.long==cat.description)
      # not a great test but just checking that the import hasn't added .0 to the end
      # as the category is an integer
      assert(cat.short.length==1)
    end

    #========== the second category column: plot =============#
    column_plot = dataset.datacolumns.where(columnnr: 7).first

    assert_not_nil column_plot
    assert_equal 'plot', column_plot.columnheader
    assert_equal 'CSP plot', column_plot.datagroup.description
    assert_equal 'P27', column_plot.sheetcells.where(row_number: 28).first.import_value

    importcats = column_plot.import_categories
    assert_equal 18, importcats.count, "There are not 18 import categories for this column"
    # unreckognized_user is found
    assert_match "firstname_unknown", column_plot.acknowledge_unknown

    importcats.each do |cat|
      # test that it still has it's decimal point
      assert(cat.short =~ /\.\d{2}$/, "#{cat.short} does not have a decimal place")
    end

    #======= the third category column: category2 ==============#
    column_category2 = dataset.datacolumns.where(columnheader: 'category2').first

    assert_not_nil column_category2
    assert_equal 'category2', column_category2.columnheader

    importcats = column_category2.import_categories
    assert_equal 6, importcats.count, "There should be 6 import categories for this column"

    uniquelist = importcats.uniq_by(&:short)
    assert_equal 3, uniquelist.count, "There should be 3 unique import categories for this column"

    #==============================================================#
    #========= approve the third column: category2================#
    column_category2.add_data_values
    # check that there aren't duplicate categories in the datagroup
    datagroup = column_category2.datagroup
    cats = datagroup.categories
    assert(!cats.nil?)
    assert(cats.count==3, "There are not 3 categories in the datagroup")
    uniquelist2 = cats.map{ |c|c.short }.uniq
    assert(uniquelist2.count==3, "There are not 3 unique categories in the datagroup")

    #============== approve the first number column: number1 ===========#
    column_number1.add_data_values
    #check whether there is 4 invlid values
    assert_equal column_number1.invalid_values.count, 4, "column number1 does not have 4 invalid values"

    #clean up
    dataset.current_datafile.destroy
  end

  test "import_duplicate_datagroups_with_different_descriptions" do
    datafile1 = Datafile.create(:file => File.new(File.join(fixture_path, 'test_files_for_uploads',
                                                           'UnitTestSpreadsheetForUpload_new.xls')))
    dataset1 = Dataset.create(:title => "just4testing_datagroups_1")
    dataset1.current_datafile = datafile1

    assert_true dataset1.save, dataset1.errors

    book1 = Workbook.new(dataset1.current_datafile)
    book1.import_data

    #count number of datagroups
    datagroup_count = Datagroup.all.count

    datafile2 = Datafile.create(:file => File.new(File.join(fixture_path, 'test_files_for_uploads',
                                                               'UnitTestSpreadsheetForUpload_Datagroups.xls')))
    dataset2 = Dataset.create(:title => "just4testing_datagroups_2")
    dataset2.current_datafile = datafile2

    assert_true dataset2.save, dataset2.errors

    book2 = Workbook.new(dataset2.current_datafile)
    book2.import_data

    #check that no more datagroups were added
    assert(datagroup_count = Datagroup.all.count, "Data groups were added during the second import")

    assert_equal(dataset1.datacolumns[0].definition, dataset2.datacolumns[0].definition, "The datacolumn descriptions don't contain the same text")
    assert_not_equal(dataset1.datacolumns[1].definition, dataset2.datacolumns[1].definition, "The datacolumn descriptions contain the same text")
    assert_equal(dataset1.datacolumns[2].definition, dataset2.datacolumns[2].definition, "The datacolumn descriptionss don't contain the same text")
    assert_not_equal(dataset1.datacolumns[6].informationsource, dataset2.datacolumns[6].informationsource, "The datacolumn informationsource contain the same text")
  end

end