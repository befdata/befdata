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

  test "regular user can't create a user" do
    login_user "Phdstudentnutrientcycling"
    get :new
    assert_response :redirect
    assert_not_nil flash[:error]
  end
  test "admin can create a user" do
    login_nadrowski
    get :new
    assert_success_no_error
  end

  test "regular user can't edit user" do
    login_user "Phdstudentnutrientcycling"
    get :edit, :id => 5
    assert_response :redirect
    assert_not_nil flash[:error]
  end

  test "admin can edit user" do
    login_nadrowski
    get :edit, :id => 5
    assert_success_no_error
  end
end
