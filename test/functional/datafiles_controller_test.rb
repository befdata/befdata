require 'test_helper'

class DatafilesControllerTest < ActionController::TestCase
  setup :activate_authlogic

  test "should get download" do
    login_nadrowski
    get :download, {:id => Datafile.first}
    assert_response :success
  end
end
