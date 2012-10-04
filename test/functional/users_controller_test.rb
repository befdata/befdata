require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  setup :activate_authlogic
  test "should get index" do
    get :index
    assert_success_no_error
  end

  test "should get show user" do
    get :show, {:id => User.first.path_name}
    assert_success_no_error
  end
end
