require 'test_helper'

class Admin::DatacolumnsControllerTest < ActionController::TestCase
  setup :activate_authlogic

  test "should get index" do
    login_nadrowski
    get :index
    assert_response :success
  end

end
