require 'test_helper'

class Settings::UsersControllerTest < ActionController::TestCase
  setup :activate_authlogic

  # basic functionality

  test "normal users can see their list of details" do
    u = User.find_by_login "Phdstudentproductivity"
    login_user u.login

    get :index
    assert_success_no_error
    assert_template 'list'
  end

  test "normal users can show details in profile" do
    non_admin_user = User.find_by_login "Phdstudentproductivity"
    login_user non_admin_user.login

    get :show, :id => non_admin_user.id
    assert_success_no_error
    assert_template 'show'
  end

  test "normal users can update details in profile" do
    non_admin_user = User.find_by_login "Phdstudentproductivity"
    login_user non_admin_user.login

    get :edit, :id => non_admin_user.id
    assert_success_no_error
    assert_template 'update_form'
  end

  # access control

  test "normal users may not delete their profile" do
    u = User.find_by_login "Phdstudentproductivity"
    login_user u.login

    assert_raise do
      get :destroy, :id => non_admin_user.id
    end
  end

  test "public may not update someones profile details" do
    some_user = User.first

    assert_raise do
      get :edit, :id => some_user.id
    end
  end

  test "normal users may not edit other profile details" do
    one_user = User.find_by_login "Phdstudentproductivity"
    other_user = User.find_by_login "pinutrientcycling"
    login_user one_user.login

    assert_raise do
      get :edit, :id => other_user.id
    end
  end

  test "admins may edit other profile details" do
    some_user = User.find_by_login "Phdstudentproductivity"
    login_nadrowski

    get :edit, :id => some_user.id
    assert_success_no_error
    assert_template 'update_form'
  end

end