require 'test_helper'

class CategoriesControllerTest < ActionController::TestCase
  setup :activate_authlogic

  test "show category" do
    login_nadrowski

    get :show, :id => 61

    assert :success
  end

  test "show sheetcells cvs upload" do
    login_nadrowski

    get :upload_sheetcells, :id => 61

    assert :success
  end

  test "download sheetcell cvs" do
    login_nadrowski

    get :show, {:id => 61, :format => :cvs}

    assert :success
  end

  test "upload sheetcells cvs addes to and creates categories" do
    login_nadrowski
    f = test_file_for_upload 'category_61_sheetcells_split.csv.txt'
    category = Category.find 61
    other_category = Category.find 62
    category_old_sheetcell_count = category.sheetcells.count
    other_category_old_sheetcell_count = other_category.sheetcells.count

    post :update_sheetcells, :id => 61, :csvfile => {:file => f}

    category.reload
    other_category.reload
    new_category = Category.find_by_datagroup_id_and_short(category.datagroup_id, 'new category')
    assert_not_nil new_category

    category_new_sheetcell_count = category.sheetcells.count
    other_category_new_sheetcell_count = other_category.sheetcells.count
    new_category_sheetcell_count = new_category.sheetcells.count

    assert :success
    assert_blank flash[:error]
    assert_equal category_new_sheetcell_count, category_old_sheetcell_count - 2, "deleting sheetcells from old category"
    assert_equal other_category_new_sheetcell_count, other_category_old_sheetcell_count + 1, "adding sheetcell to other category"
    assert_equal new_category_sheetcell_count, 1, "adding sheetcell to newly created category"
  end

end