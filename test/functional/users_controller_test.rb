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
    get :edit, {:id => User.first.path_name}
    assert_response :redirect
    assert_not_nil flash[:error]
  end

  test "only allow editing of ones own profile" do
    u =  User.find_by_login("nadrowski")
    assert u.has_role?(:admin)
    login_nadrowski

    get :edit, {:id => User.find(3).path_name}
    assert_select "h2", /.*Nadrowski.*/
  end

  test "one can edit his/her own profile" do
    login_nadrowski
    get :edit, {:id => User.find_by_login("nadrowski").path_name}
    assert_success_no_error
  end 

  test "user can update its api login credentials" do
    login_nadrowski
    old_user_credentials = User.find_by_login("nadrowski").single_access_token
    get :update_credentials
    new_user_credentials = User.find_by_login("nadrowski").single_access_token
    assert_not_equal(old_user_credentials, new_user_credentials)
  end

  test "update the profile" do
    login_nadrowski
    post :update, :id => User.find_by_login("nadrowski").id, :user => {:city => 'testcity'}
    assert_redirected_to :profile
    assert_equal 'testcity', User.find_by_login("nadrowski").city
  end

  test "show open votes" do
    login_nadrowski
    get :votes
    assert_success_no_error
  end

  test "show voting history" do
    login_nadrowski
    get :votes_history
    assert_success_no_error
  end

end
