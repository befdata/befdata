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
   #TODO check if necessary
   # login_and_load_category
   # get :index
   # assert_select "td.id-column", @category.id.to_s
  end

  test "show number of links to sheetcells in index" do
    login_and_load_category
    get :index
    assert_select "td.sheetcells-column", @category.sheetcells.size.to_s
  end

  test "show number of links to categories in index" do
    login_and_load_category
    get :index
    assert_select "td.import_categories-column", @category.import_categories.size.to_s
  end

  test "show id in update" do
    login_and_load_category
    get :edit, :id => @category.id
    regex_to_match = /.* Id .* #{@category.id} .*/mox
    assert_select "dl", regex_to_match
  end

  test "show number of linked sheetcells in update" do
    login_and_load_category
    get :edit, :id => @category.id
    regex_to_match = /.* Sheetcells .* #{@category.sheetcells.size} .*/mox
    assert_select "dl", regex_to_match
  end

  test "show number of linked import categoricvalues in update" do
    login_and_load_category
    get :edit, :id => @category.id
    regex_to_match = /.* Import.categories .* #{@category.import_categories.size} .*/mox
    assert_select "dl", regex_to_match
  end

end
