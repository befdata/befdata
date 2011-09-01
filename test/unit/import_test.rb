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
    end

end