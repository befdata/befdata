require 'test_helper'

class FilevaluesControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:filevalues)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create filevalue" do
    assert_difference('Filevalue.count') do
      post :create, :filevalue => { }
    end

    assert_redirected_to filevalue_path(assigns(:filevalue))
  end

  test "should show filevalue" do
    get :show, :id => filevalues(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => filevalues(:one).to_param
    assert_response :success
  end

  test "should update filevalue" do
    put :update, :id => filevalues(:one).to_param, :filevalue => { }
    assert_redirected_to filevalue_path(assigns(:filevalue))
  end

  test "should destroy filevalue" do
    assert_difference('Filevalue.count', -1) do
      delete :destroy, :id => filevalues(:one).to_param
    end

    assert_redirected_to filevalues_path
  end
end
