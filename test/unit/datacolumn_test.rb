require 'test_helper'
 
class DatacolumnTest < ActiveSupport::TestCase

  # uploaded_values should return the first n unique uploaded values for the datacolumn.
  test "imported_values_test_number_returned" do
    n = 2
    datacolumn = Datacolumn.find(33)
    firstN = datacolumn.imported_values(n)
    assert(firstN.length==n)
  end

   test "imported_values_test_uniqueness" do
    n = 3
    datacolumn = Datacolumn.find(36)
    firstN = datacolumn.imported_values(n)
    array = firstN.collect{ |f| f[:import_value] }
    assert(array.uniq.length==n)
   end

  test "accepted_values_test_number_returned" do
    n = 2
    datacolumn = Datacolumn.find(33)
    firstN = datacolumn.accepted_values(n)
    assert(firstN.length==n)
  end

  test "accepted_values_test_uniqueness" do
    n = 3
    datacolumn = Datacolumn.find(36)
    firstN = datacolumn.accepted_values(n)
    array = firstN.collect{ |f| f[:accepted_value] }
    assert(array.uniq.length==n)
  end

  test "values_stored" do
    datacolumn = Datacolumn.find(34)
    assert(datacolumn.values_stored?)
  end

  test "accept_text_datacolumn_values" do
    datacolumn = Datacolumn.find(41)
    datacolumn.add_data_values()

    datacolumn.sheetcells.each do |cell|
      assert(cell.import_value == cell.accepted_value)
      assert(cell.status_id == 4)
    end
  end

  test "accept_number_datacolumn_values" do
    datacolumn = Datacolumn.find(42)
    datacolumn.add_data_values()

    valid_numbers=0
    datacolumn.sheetcells.each do |cell|
      if cell.import_value == cell.accepted_value then
        # check that the data type is still a number
        assert(cell.datatype_id == 7)
        assert(cell.status_id == Sheetcellstatus::VALID)
        valid_numbers += 1
      else
        # if it's not a valid number then a category will have been created
        assert(cell.datatype_id == 5)
        assert(cell.status_id == Sheetcellstatus::INVALID)
      end
    end
    # there should be 6 valid numbers
    assert(valid_numbers == 6)
  end

  test "accept_date_1_datacolumn_values" do
    datacolumn = Datacolumn.find(43)
    datacolumn.add_data_values()

    valid_dates=0
    datacolumn.sheetcells.each do |cell|
      if cell.import_value == cell.accepted_value then
        # check that the data type is still a date
        assert(cell.datatype_id == 3)
        valid_dates += 1
        assert(cell.status_id == Sheetcellstatus::VALID)
      else
        # if it's not a valid date then a category will have been created
        assert(cell.datatype_id == 5)
        assert(cell.status_id == Sheetcellstatus::INVALID)
      end
    end
    # there should be 6 valid dates
    assert(valid_dates == 6)
  end

  test "accept_year_datacolumn_values" do
    datacolumn = Datacolumn.find(44)
    datacolumn.add_data_values()

    valid_years=0
    datacolumn.sheetcells.each do |cell|
      if cell.import_value == cell.accepted_value then
        # check that the data type is still a year
        assert(cell.datatype_id == 2)
        valid_years += 1
        assert(cell.status_id == Sheetcellstatus::VALID)
      else
        # if it's not a valid year then a category will have been created
        assert(cell.datatype_id == 5)
        assert(cell.status_id == Sheetcellstatus::INVALID)
      end
    end
    # there should be 6 valid years
    assert(valid_years == 6)
  end

  test "accept_sheet_match_category_datacolumn_values" do
    datacolumn = Datacolumn.find(45)
    datacolumn.add_data_values()

    sheet_match_count = 0
    invalid_count = 0
    datacolumn.sheetcells.each do |cell|
      assert(cell.category_id > 0, "A category id has not been set")
      if(cell.status_id == Sheetcellstatus::SHEET_MATCH) then
        sheet_match_count += 1
      elsif(cell.status_id == Sheetcellstatus::INVALID) then
        invalid_count += 1
      end
    end
    assert(sheet_match_count == 7, "Sheet match count doesn't equal 7")
    assert(invalid_count == 1, "Invalid count doesn't equal 1")
  end

  test "accept_category_datacolumn_values" do
    datacolumn = Datacolumn.find(46)
    datacolumn.add_data_values()

    sheet_match_count = 0
    invalid_count = 0
    portal_match_count=0
    datacolumn.sheetcells.each do |cell|
      assert(cell.category_id > 0, "A category id has not been set")
      if(cell.status_id == Sheetcellstatus::SHEET_MATCH) then
        sheet_match_count += 1
      elsif(cell.status_id == Sheetcellstatus::INVALID) then
        invalid_count += 1
      elsif(cell.status_id == Sheetcellstatus::PORTAL_MATCH) then
        invalid_count += 1
      end
    end
    assert(sheet_match_count == 0, "Sheet match count doesn't equal 0")
    assert(invalid_count == 8, "Invalid count doesn't equal 8")
    assert(portal_match_count == 0, "Portal match count doesn't equal 0")
  end

  test "accept_date_2_datacolumn_values" do
    datacolumn = Datacolumn.find(47)
    datacolumn.add_data_values()

    valid_dates=0
    datacolumn.sheetcells.each do |cell|
      if cell.import_value == cell.accepted_value then
        # check that the data type is still a date
        assert(cell.datatype_id == 4)
        valid_dates += 1
        assert(cell.status_id == Sheetcellstatus::VALID)
      else
        # if it's not a valid date then a category will have been created
        assert(cell.datatype_id == 5)
        assert(cell.status_id == Sheetcellstatus::INVALID)
      end
    end
    # there should be 7 valid dates
    assert(valid_dates == 7, "There are not 6 valid dates")
  end

  test "accept_number_2_datacolumn_values" do
    datacolumn = Datacolumn.find(48)
    datacolumn.add_data_values()

    valid_numbers=0
    datacolumn.sheetcells.each do |cell|
      if cell.import_value == cell.accepted_value then
        # check that the data type is still a number
        assert(cell.datatype_id == 7)
        assert(cell.status_id == Sheetcellstatus::VALID)
        valid_numbers += 1
      else
        # if it's not a valid number then a category will have been created
        assert(cell.datatype_id == 5)
        assert(cell.status_id == Sheetcellstatus::INVALID)
      end
    end
    # there should be 6 valid numbers
    assert(valid_numbers == 6, "There are not 6 valid numbers")
  end
end
