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

  test "public should not be able to edit users' profile" do
    get :edit, {:id=>User.first.path_name}
    assert_response :redirect
    assert_not_nil flash[:error]
  end

  test "only allow editing of ones own profile" do
    u =  User.find_by_login("nadrowski")
    assert u.has_role?(:admin)
    login_nadrowski

    get :edit, {:id=>User.find(3).path_name}
    assert_select "h2", /.*Nadrowski.*/
  end

  test "one can edit his/her own profile" do
    login_nadrowski
    get :edit,{:id=>User.find_by_login("nadrowski").path_name}
    assert_success_no_error
  end
end
