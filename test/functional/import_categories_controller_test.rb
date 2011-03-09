require 'test_helper'

class ImportCategoriesControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:import_categories)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create import_category" do
    assert_difference('ImportCategory.count') do
      post :create, :import_category => { }
    end

    assert_redirected_to import_category_path(assigns(:import_category))
  end

  test "should show import_category" do
    get :show, :id => import_categories(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => import_categories(:one).to_param
    assert_response :success
  end

  test "should update import_category" do
    put :update, :id => import_categories(:one).to_param, :import_category => { }
    assert_redirected_to import_category_path(assigns(:import_category))
  end

  test "should destroy import_category" do
    assert_difference('ImportCategory.count', -1) do
      delete :destroy, :id => import_categories(:one).to_param
    end

    assert_redirected_to import_categories_path
  end
end
