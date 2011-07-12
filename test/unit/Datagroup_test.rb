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

end