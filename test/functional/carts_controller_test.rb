require 'test_helper'

class CartsControllerTest < ActionController::TestCase
  setup :activate_authlogic

  test "should show cart" do
    login_nadrowski

    get :show
    assert_success_no_error
  end
end
