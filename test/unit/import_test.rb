require 'test_helper'

class ImportTest < ActiveSupport::TestCase

  test "import_categorysheet_values" do
    datafile = Datafile.create(:file => File.new(File.join(fixture_path, 'test_files_for_uploads',
                                                           'UnitTestSpreadsheetForUpload.xls')))
    datafile.save
    dataset = Dataset.new(:title => "Unit test")
    dataset.upload_spreadsheet = datafile
    dataset.save
    book = Dataworkbook.new(dataset.upload_spreadsheet)
    book.import_data

    # the first category column
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

    # the second category column
    datacolumn = Datacolumn.first(:conditions => ["dataset_id = ? and columnheader = 'plot'", dataset.id])
    assert(!datacolumn.nil?)
    importcats = datacolumn.import_categories
    assert(!importcats.nil?)
    assert(importcats.count==22, "There are not 22 import categories for this column")

    importcats.each do |cat|
      # test that it still has it's decimal point
      assert(cat.short =~ /\.[0-9][0-9]$/, "#{cat.short} does not have a decimal place")
    end

    # the third category column
    datacolumn = Datacolumn.first(:conditions => ["dataset_id = ? and columnheader = 'category2'", dataset.id])
    assert(!datacolumn.nil?)
    importcats = datacolumn.import_categories
    assert(!importcats.nil?)
    assert(importcats.count==6, "There are not 6 import categories for this column")
    uniquelist = importcats.map{ |c|c.short }.uniq
    assert(!uniquelist.nil?)
    assert(uniquelist.count==3, "There are not 3 unique import categories for this column")

    # approve the third column
    datacolumn.add_data_values(User.find(1))
    # check that there aren't duplicate categories in the datagroup
    datagroup = datacolumn.datagroup
    cats = datagroup.categories
    assert(!cats.nil?)
    assert(cats.count==3, "There are not 3 categories in the datagroup")
    uniquelist2 = cats.map{ |c|c.short }.uniq
    assert(uniquelist2.count==3, "There are not 3 unique categories in the datagroup")
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

end