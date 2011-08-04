require 'test_helper'
require 'spreadsheet'

class DataworkbookTest < ActiveSupport::TestCase

  def setup
    @dataset = Dataset.find(5)
    @spreadsheet = Spreadsheet.open @dataset.upload_spreadsheet.file.path
    @spreadsheet.io.close
    @book = Dataworkbook.new(@dataset.upload_spreadsheet)
  end

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
    assert_equal 4, @book.columnheaders_raw.length
  end
  
  test "workbook should have unique column headers" do
    assert @book.columnheaders_unique?
  end
  
  test "workbook should contain two people" do
    assert_equal 2, @book.people_names_hash.length
  end
  
  test "start date of workbook should be April 18th, 2011" do
    assert_equal Date.new(2011, 4, 18), @book.datemin
  end
  
  test "end date of workbook should be April 18th, 2011" do
    assert_equal Date.new(2011, 4, 18), @book.datemax
  end
  
  test "general metadata hash should fill up correctly" do
    assert_equal 'Test species name import', @book.general_metadata_hash[:title] 
    assert_match /Comparative Study Plots/,  @book.general_metadata_hash[:abstract]
    assert_match /National Forest Reserve/, @book.general_metadata_hash[:spatialextent]
  end
  
  test "array of metadata column is correct" do
    assert_equal @book.general_metadata_column.first, 'General Metadata'
    assert_equal @book.general_metadata_column.length, 49
  end

  test "hash of people named in the workbook is correct" do
    assert_equal 2, @book.people_names_hash.length
    assert_equal "Karin", @book.people_names_hash.first[:firstname]
    assert_equal "Verena", @book.people_names_hash.second[:firstname]
  end
  
  test "method index for a specific columnheader is correct" do
    assert_equal 9, @book.method_index_for_columnheader('height')
  end
  
  test "column info for columnheader is correct" do
    assert_equal 7, @book.data_column_info_for_columnheader('height').keys.length
    assert_equal 'height in m', @book.data_column_info_for_columnheader('height')[:definition]
  end
  
  test "datagroup information for columnheader is correct" do
    assert_equal 7, @book.methodsheet_datagroup('height').keys.length
    assert_equal 'number', @book.methodsheet_datagroup('height')[:methodvaluetype]
  end
  
  test "data with head is correct for columnheader" do
    assert_equal 5, @book.data_with_head('height').length
    assert_equal 3.0, @book.data_with_head('height').third
  end
  
  test "datagroup title for columnheader is correct" do
    assert_equal 4,  @book.data_for_columnheader('height')[:rowmax]
    assert_equal 'na',  @book.data_for_columnheader('height')[:data][4]
  end
end
