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
  test "logged-in user can see 'Edit profile' in his/her page" do
    login_user(User.first.login)

    get :show, :id=>User.first.path_name
    assert_response :success
    assert_select "div#actions a", "Edit profile"

    get :show, :id=>User.last.path_name
    assert_response :success
    assert_select "div#actions a", false
  end

end
