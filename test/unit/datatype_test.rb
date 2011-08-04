require 'test_helper'

class DatatypeTest < Test::Unit::TestCase

  # datatypes should be loaded at application start up
  test "datatype_count" do
    datatype_count = Datatypehelper::DATATYPE_COLLECTION.length
    assert(datatype_count==6, "Datatype collection length is not 6")
  end

  test "category_datatype_find_by_id" do
    datatype = Datatypehelper.find_by_id(5)
    assert(datatype.name=="category", "Could not find category datatype using id 5")
  end

  test "year_datatype_find_by_name" do
    datatype = Datatypehelper.find_by_name("year")
    assert(datatype.id==2, "Could not find year datatype by name")
  end


end
