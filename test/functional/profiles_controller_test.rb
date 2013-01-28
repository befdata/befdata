require 'test_helper'

class ProfilesControllerTest < ActionController::TestCase
  setup :activate_authlogic

  test "public can't visit profile page" do
    get :show
    assert_not_nil flash[:error]
    get :edit
    assert_not_nil flash[:error]
  end
  test "logged-in user can visit profile page" do
    login_nadrowski
    get :show
    assert_success_no_error
  end

  test "one can edit his/her own profile" do
    login_nadrowski
    get :edit
    assert_success_no_error
  end
  test "one can update the profile" do
    login_nadrowski
    post :update, :user => {:city => 'testcity'}
    assert_redirected_to "/profile"
    assert_equal 'testcity', User.find_by_login("nadrowski").city
  end
  test "updating should ignore restrictive parameters" do
    login_user "Phdstudentnutrientcycling"
    post :update, :user => {:city => 'testcity', :admin => "1", :project_board => "1"}
    assert_success_no_error
    u = User.find_by_login("Phdstudentnutrientcycling")
    assert !u.admin
    assert !u.project_board
  end
  test "user can update its api login credentials" do
    login_nadrowski
    old_user_credentials = User.find_by_login("nadrowski").single_access_token
    get :update_credentials
    new_user_credentials = User.find_by_login("nadrowski").single_access_token
    assert_not_equal(old_user_credentials, new_user_credentials)
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
