require 'test_helper'
require 'spreadsheet'

class DataworkbookTest < ActiveSupport::TestCase

  def setup
    @dataset = Dataset.find(5)
    @spreadsheet = Spreadsheet.open @dataset.upload_spreadsheet.file.path
    @spreadsheet.io.close
    @book = Dataworkbook.new(@dataset.upload_spreadsheet, @spreadsheet)
  end

  # Replace this with your real tests.
  test "workbook was loaded correctly" do
    assert_not_nil @book
  end
  
  test "workbook should have five worksheets" do
    assert @book.general_metadata_sheet.kind_of?(Spreadsheet::Excel::Worksheet)
    assert @book.data_description_sheet.kind_of?(Spreadsheet::Excel::Worksheet)
    assert @book.data_responsible_person_sheet.kind_of?(Spreadsheet::Excel::Worksheet)
    assert @book.data_categories_sheet.kind_of?(Spreadsheet::Excel::Worksheet)
    assert @book.raw_data_sheet.kind_of?(Spreadsheet::Excel::Worksheet)
  end
  
  test "workbook should have four column headers" do
    assert_equal @book.columnheaders_raw.length, 4
  end
  
  test "workbook should have unique column headers" do
    assert @book.columnheaders_unique?
  end
  
  test "workbook should contain two people" do
    assert_equal @book.people_names_hash.length, 2
  end
  
  test "start date of workbook should be April 18th, 2011" do
    assert_equal @book.datemin, Date.new(2011, 4, 18)
  end
  test "end date of workbook should be April 18th, 2011" do
    assert_equal @book.datemax, Date.new(2011, 4, 18)
  end
end
