require 'test_helper'

class Settings::UsersControllerTest < ActionController::TestCase
  setup :activate_authlogic

  # basic functionality

  test "normal users can see their list of details" do
    non_admin_user = (User.all - User.joins(:role_objects).where('"roles"."name" = \'admin\'')).first
    login_user non_admin_user.login

    get :index
    assert_response :success
    assert_template 'list'
  end

  test "normal users can show details in profile" do
    non_admin_user = non_admin_users.first
    login_user non_admin_user.login

    get :show, :id => non_admin_user.id
    assert_response :success
    assert_template 'show'
  end

  test "normal users can update details in profile" do
    non_admin_user = non_admin_users.first
    login_user non_admin_user.login

    get :edit, :id => non_admin_user.id
    assert_response :success
    assert_template 'update_form'
  end

  # access control

  test "normal users may not delete their profile" do
    non_admin_user = non_admin_users.first
    login_user non_admin_user.login
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
    users = non_admin_users
    one_user = users.first
    other_user = (users - [one_user]).first

    login_user one_user.login
    assert_raise do
      get :edit, :id => other_user.id
    end
  end

  test "admins may edit other profile details" do
    some_user = non_admin_users.first
    login_nadrowski
    get :edit, :id => some_user.id
    assert_response :success
    assert_template 'update_form'
  end

end