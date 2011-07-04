require 'test_helper'

class Admin::CategoricvaluesControllerTest < ActionController::TestCase
  setup :activate_authlogic

  test "should get index" do
    login_nadrowski
    get :index
    assert_response :success
    assert_template 'list'
  end

  test "should get update" do
    login_and_load_categoricvalue
    get :edit, :id => @categoricvalue.id
    assert_response :success
    assert_template 'update_form'
  end

  test "show id in index" do
    login_and_load_categoricvalue
    get :index
    assert_select "td.id-column", @categoricvalue.id.to_s
  end

  test "show number of links to sheetcells and categoricvalues in index" do
    login_and_load_categoricvalue
    get :index
    text_for_links = "#{@categoricvalue.sheetcells.size}, #{@categoricvalue.import_categoricvalues.size}"
    assert_select "td.links-column", text_for_links
  end

  test "show id in update" do
    login_and_load_categoricvalue
    get :edit, :id => @categoricvalue.id
    regex_to_match = /.* Id .* #{@categoricvalue.id} .*/mox
    assert_select "dl", regex_to_match
  end

  test "show number of linked sheetcells in update" do
    login_and_load_categoricvalue
    get :edit, :id => @categoricvalue.id
    regex_to_match = /.* Sheetcells .* #{@categoricvalue.sheetcells.size} .*/mox
    assert_select "dl", regex_to_match
  end

  test "show number of linked import categoricvalues in update" do
    login_and_load_categoricvalue
    get :edit, :id => @categoricvalue.id
    regex_to_match = /.* Import.categoricvalues .* #{@categoricvalue.import_categoricvalues.size} .*/mox
    assert_select "dl", regex_to_match
  end

end
