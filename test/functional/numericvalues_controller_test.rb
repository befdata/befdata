require 'test_helper'

class NumericvaluesControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:numericvalues)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create numericvalue" do
    assert_difference('Numericvalue.count') do
      post :create, :numericvalue => { }
    end

    assert_redirected_to numericvalue_path(assigns(:numericvalue))
  end

  test "should show numericvalue" do
    get :show, :id => numericvalues(:one).id
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => numericvalues(:one).id
    assert_response :success
  end

  test "should update numericvalue" do
    put :update, :id => numericvalues(:one).id, :numericvalue => { }
    assert_redirected_to numericvalue_path(assigns(:numericvalue))
  end

  test "should destroy numericvalue" do
    assert_difference('Numericvalue.count', -1) do
      delete :destroy, :id => numericvalues(:one).id
    end

    assert_redirected_to numericvalues_path
  end
end
