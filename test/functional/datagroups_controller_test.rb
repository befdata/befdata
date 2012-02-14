require 'test_helper'

class DatagroupsControllerTest < ActionController::TestCase
  setup :activate_authlogic

  test "show index of datagroups" do
    login_nadrowski

    get :index

    assert :success
  end

  test "show datagroup" do
    login_nadrowski

    get :show, :id => Datagroup.first.id

    assert :success
  end

  test "show datagroup cvs upload" do
    login_nadrowski

    get :upload_categories, :id => Datagroup.first.id

    assert :success
  end

  test "download categories cvs" do
    login_nadrowski

    get :show, {:id => 22, :format => :cvs}

    assert :success
  end

  test "upload updated categories cvs" do
    login_nadrowski
    request.env["HTTP_REFERER"] = root_url
    f = test_file_for_upload 'datagroup_22_categories.csv.txt'

    post :update_categories, :id => 22, :csvfile => {:file => f}

    assert :success
    assert_blank flash[:error]
  end

  test "dont accept duplicate categories short via cvs" do
    login_nadrowski
    request.env["HTTP_REFERER"] = root_url
    f = test_file_for_upload 'datagroup_22_categories_faulty.csv.txt'

    post :update_categories, :id => 22, :csvfile => {:file => f}

    assert :success
    assert_match /.*unique.*/, flash[:error]
  end

end