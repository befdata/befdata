require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  # Replace this with your real tests.
  test "should get index" do
    get :index
    assert_response :success
  end

  test "should get show user" do
    get :show, {:id => User.first.path_name}
    assert_response :success
  end
end
