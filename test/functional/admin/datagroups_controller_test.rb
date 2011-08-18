require 'test_helper'

class Admin::DatagroupsControllerTest < ActionController::TestCase
  setup :activate_authlogic

  test "should get index" do
    login_nadrowski
    get :index
    assert_response :success
  end

  test "show datacolumns number in list" do
    login_nadrowski
    datagroup = Datagroup.first
    get :index
    assert_select "td.datacolumns-column", datagroup.datacolumns.size.to_s
  end

  test "show datacolumns number in update" do
    login_nadrowski
    datagroup = Datagroup.first
    get :edit, :id => datagroup.id
    regex_to_match = /.* Datacolumns .* #{datagroup.datacolumns.size} .*/mox
    assert_select "dl", regex_to_match
  end

  test "show delete link only when no datacolumns linked" do
    dg_with_dc = Datagroup.find 1
    dg_without_dc =  Datagroup.find 7

    login_nadrowski
    get :index

    delete_link_selector = "tr#as_admin__datagroups-list-ID-row a.destroy"
    dg_without_dc_selector = delete_link_selector.sub "ID", dg_without_dc.id.to_s
    dg_with_dc_selector = delete_link_selector.sub "ID", dg_with_dc.id.to_s
    assert_select dg_without_dc_selector
    assert_select dg_with_dc_selector, 0
  end
  
end
