require 'test_helper'

class Admin::CategoriesControllerTest < ActionController::TestCase
  setup :activate_authlogic

  test "should get index" do
    login_nadrowski
    get :index
    assert_response :success
    assert_template 'list'
  end

  test "should get update" do
    login_and_load_category
    get :edit, :id => @category.id
    assert_response :success
    assert_template 'update_form'
  end

  test "show id in index" do
   login_and_load_category
   get :index
   assert_select "td.id-column", @category.id.to_s
  end

  test "show number of linked sheetcells in update" do
    login_and_load_category
    get :edit, :id => @category.id
    regex_to_match = /Sheetcells/
    assert_select "label", regex_to_match
  end

end
