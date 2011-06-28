require 'test_helper'
 
class DatacolumnTest < ActiveSupport::TestCase

  # uploaded_values should return the first n unique uploaded values for the datacolumn.
  test "imported_values_test_number_returned" do
    n = 2
    datacolumn = Datacolumn.find(33)
    firstN = datacolumn.imported_values(n)
    assert (firstN.length==n)
  end

   test "imported_values_test_uniqueness" do
    n = 3
    datacolumn = Datacolumn.find(36)
    firstN = datacolumn.imported_values(n)
    array = firstN.collect{ |f| f[:import_value] }
    assert (array.uniq.length==n)
   end

  test "accepted_values_test_number_returned" do
    n = 2
    datacolumn = Datacolumn.find(33)
    firstN = datacolumn.accepted_values(n)
    assert (firstN.length==n)
  end

  test "accepted_values_test_uniqueness" do
    n = 3
    datacolumn = Datacolumn.find(36)
    firstN = datacolumn.accepted_values(n)
    array = firstN.collect{ |f| f[:accepted_value] }
    assert (array.uniq.length==n)
  end

  test "values_stored" do
    datacolumn = Datacolumn.find(34)
    assert (datacolumn.values_stored?)
  end
end
