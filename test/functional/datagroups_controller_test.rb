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
    f = test_file_for_upload 'datagroup_22_categories_update.csv.txt'

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

  test "merge categories via csv" do
    login_nadrowski
    f = test_file_for_upload 'datagroup_22_categories_merge.csv.txt'
    cat_count_old = Datagroup.find(22).categories.count

    post :update_categories, :id => 22, :csvfile => {:file => f}
    cat_count_new = Datagroup.find(22).categories.count

    assert :success
    assert_blank flash[:error]
    assert cat_count_new = (cat_count_old - 3)
  end

end