require 'test_helper'

class Admin::DatasetsControllerTest < ActionController::TestCase
  setup :activate_authlogic

  test "should get index" do
    login_nadrowski
    get :index
    assert_success_no_error
    assert_template 'list'
  end

  test "should get show" do
    login_nadrowski
    get :show, :id => Dataset.first.id
    assert_success_no_error
    assert_template 'show'
  end

  test "should get edit" do
    login_nadrowski
    get :edit, :id => Dataset.first.id
    assert_success_no_error
    assert_template 'update'
  end

end
