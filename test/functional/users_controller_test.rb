require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  setup :activate_authlogic
  test "should get index" do
    get :index
    assert_response :success
  end

  test "should get show user" do
    get :show, {:id => User.first.path_name}
    assert_response :success
  end
end
