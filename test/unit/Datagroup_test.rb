require 'test_helper'

class DatagroupText < ActiveSupport::TestCase

  test "delete_system_datagroup" do
    datagroup = Datagroup.find(:first, :conditions => [ "system = true", :limit => 1])
    if(!datagroup.nil?)
      assert_raise(Exception, "Cannot destroy a system datagroup"){
        Datagroup.destroy(datagroup.id)
      }
    end
  end

end