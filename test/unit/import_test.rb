require 'test_helper'

class ImportTest < ActiveSupport::TestCase
self.use_transactional_fixtures = false

  test "upload_import_and_approve_dataset" do
    ##upload a dataworkbook
    datafile = Datafile.create(:file => File.new(File.join(fixture_path, 'test_files_for_uploads',
                                                           'UnitTestSpreadsheetForUpload_new.xls')))
    assert_true datafile.save, datafile.errors

    dataset = Dataset.create(:title => "just4testing")
    dataset.current_datafile = datafile

    assert_true dataset.save, dataset.errors

    ##import dataset
    book = Dataworkbook.new(dataset.current_datafile)
    book.import_data

    # the first number column: number1
    datacolumn = Datacolumn.first(:conditions => ["dataset_id=? and columnheader='number1'", dataset.id])
    assert_not_nil datacolumn
    assert_equal datacolumn.sheetcells.count,27, "column number1 does not have 27 values inported"

    # the first category column: category
    datacolumn = Datacolumn.first(:conditions => ["dataset_id = ? and columnheader = 'category'", dataset.id])
    assert(!datacolumn.nil?)
    importcats = datacolumn.import_categories
    assert(!importcats.nil?)

    importcats.each do |cat|
      # only a short value was provided
      assert(cat.short==cat.long && cat.long==cat.description)
      # not a great test but just checking that the import hasn't added .0 to the end
      # as the category is an integer
      assert(cat.short.length==1)
    end

    # the second category column: plot
    datacolumn = Datacolumn.first(:conditions => ["dataset_id = ? and columnheader = 'plot'", dataset.id])
    assert(!datacolumn.nil?)
    importcats = datacolumn.import_categories
    assert(!importcats.nil?)
    assert(importcats.count==18, "There are not 18 import categories for this column")
    # unreckognized_user is found
    assert_match "firstname_unknown", datacolumn.acknowledge_unknown

    importcats.each do |cat|
      # test that it still has it's decimal point
      assert(cat.short =~ /\.[0-9][0-9]$/, "#{cat.short} does not have a decimal place")
    end

    # the third category column: category2
    datacolumn = Datacolumn.first(:conditions => ["dataset_id = ? and columnheader = 'category2'", dataset.id])
    assert(!datacolumn.nil?)
    importcats = datacolumn.import_categories
    assert(!importcats.nil?)
    assert(importcats.count==6, "There are not 6 import categories for this column")
    uniquelist = importcats.map{ |c|c.short }.uniq
    assert(!uniquelist.nil?)
    assert(uniquelist.count==3, "There are not 3 unique import categories for this column")

    ##approve
    # approve the third column: category2
    datacolumn.add_data_values(User.find(1))
    # check that there aren't duplicate categories in the datagroup
    datagroup = datacolumn.datagroup
    cats = datagroup.categories
    assert(!cats.nil?)
    assert(cats.count==3, "There are not 3 categories in the datagroup")
    uniquelist2 = cats.map{ |c|c.short }.uniq
    assert(uniquelist2.count==3, "There are not 3 unique categories in the datagroup")

    # approve the first number column: number1
    datacolumn = Datacolumn.first(:conditions => ["dataset_id=? and columnheader = 'number1'",dataset.id])
    datacolumn.add_data_values(User.find(1))
    #check whether there is 4 invlid values
    assert_equal datacolumn.invalid_values.count, 4, "column number1 does not have 4 invalid values"

    #clean up
    dataset.current_datafile.destroy
  end

  test "cleanstring_several_spaces" do
    input = "     testing spaces "
    cleanstring = input.gsub(/^[\s]+|[\s]+$/,"")
    assert(cleanstring=="testing spaces")
  end

  test "cleanstring_no_spaces" do
    input = "testing spaces"
    cleanstring = input.gsub(/^[\s]+|[\s]+$/,"")
    assert(cleanstring=="testing spaces")
  end

  test "import_duplicate_datagroups_with_different_descriptions" do
    datafile1 = Datafile.create(:file => File.new(File.join(fixture_path, 'test_files_for_uploads',
                                                           'UnitTestSpreadsheetForUpload_new.xls')))
    datafile2 = Datafile.create(:file => File.new(File.join(fixture_path, 'test_files_for_uploads',
                                                               'UnitTestSpreadsheetForUpload_Datagroups.xls')))
    dataset1 = Dataset.create(:title => "just4testing_datagroups_1")
    dataset1.current_datafile = datafile1

    assert_true dataset1.save, dataset1.errors

    book1 = Dataworkbook.new(dataset1.current_datafile)
    book1.import_data

    #count number of datagroups
    datagroup_count = Datagroup.all.count

    dataset2 = Dataset.create(:title => "just4testing_datagroups_2")
    dataset2.current_datafile = datafile2

    assert_true dataset2.save, dataset2.errors

    book2 = Dataworkbook.new(dataset2.current_datafile)
    book2.import_data

    #check that no more datagroups were added
    assert(datagroup_count = Datagroup.all.count,"Data groups were added during the second import")

    assert_equal(dataset1.datacolumns[0].definition, dataset2.datacolumns[0].definition, "The datacolumn descriptions don't contain the same text")
    assert_not_equal(dataset1.datacolumns[1].definition, dataset2.datacolumns[1].definition, "The datacolumn descriptions contain the same text")
    assert_equal(dataset1.datacolumns[2].definition, dataset2.datacolumns[2].definition, "The datacolumn descriptionss don't contain the same text")
    assert_not_equal(dataset1.datacolumns[6].informationsource, dataset2.datacolumns[6].informationsource, "The datacolumn informationsource contain the same text")
  end

end