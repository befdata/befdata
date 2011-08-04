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
   #TODO The tested code does not show an Id.  
   # login_and_load_category
   # get :index
   # assert_select "td.id-column", @category.id.to_s
  end

  test "show number of links to sheetcells in index" do
#    TODO The tested code does not show a number of sheetcells
#    login_and_load_category
#    get :index
#    assert_select "td.long-column", @category.sheetcells.size.to_s
  end

  test "show number of links to categories in index" do
#    TODO The tested code doeas not show any link to a category
#    login_and_load_category
#    get :index
#    assert_select "td.categories-column", @category.import_categories.size.to_s
  end

  test "show id in update" do
#    TODO The tested code does not show an Id.  
#    login_and_load_category
#    get :edit, :id => @category.id
#    regex_to_match = /.* Id .* #{@category.id} .*/mox
#    assert_select "dl", regex_to_match
  end

  test "show number of linked sheetcells in update" do
    login_and_load_category
    get :edit, :id => @category.id
    regex_to_match = /Sheetcells/
    assert_select "label", regex_to_match
  end

  test "show number of linked import categoricvalues in update" do
#    TODO The tested code does not show any number of categoric values
#    login_and_load_category
#    get :edit, :id => @category.id
#    regex_to_match = /.* Import.categories .* #{@category.import_categories.size} .*/mox
#    assert_select "dl", regex_to_match
  end
end
