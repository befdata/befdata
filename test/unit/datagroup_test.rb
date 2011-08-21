require 'test_helper'

class DatagroupText < ActiveSupport::TestCase

  test "delete_system_datagroup" do
    datagroup = Datagroup.where(:type_id => Datagrouptype::HELPER).first
    if(!datagroup.nil?)
      assert_raise(Exception, "Cannot destroy a system datagroup"){
        Datagroup.destroy(datagroup.id)
      }
    end
  end

  test "create_datagroup_test_for_default_type" do
    datagroup = Datagroup.create!(:title => "Unit test",
                                :description => "Unit test datagroup")
    assert(!datagroup.nil?, "The data group was not created")
    if(!datagroup.nil?)
      assert(datagroup.type_id=1, "The datagroup does not have the default type id")
    end
  end


end