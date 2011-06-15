require 'test_helper'
require 'authlogic/test_case'

class CartsControllerTest < ActionController::TestCase
  setup :activate_authlogic

  test "should show cart" do
    login_nadrowski

    get :show
    assert_response :success
  end
end
