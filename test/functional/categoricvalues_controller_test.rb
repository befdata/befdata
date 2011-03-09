require 'test_helper'

class CategoricvaluesControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:categoricvalues)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create categoricvalue" do
    assert_difference('Categoricvalue.count') do
      post :create, :categoricvalue => { }
    end

    assert_redirected_to categoricvalue_path(assigns(:categoricvalue))
  end

  test "should show categoricvalue" do
    get :show, :id => categoricvalues(:one).id
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => categoricvalues(:one).id
    assert_response :success
  end

  test "should update categoricvalue" do
    put :update, :id => categoricvalues(:one).id, :categoricvalue => { }
    assert_redirected_to categoricvalue_path(assigns(:categoricvalue))
  end

  test "should destroy categoricvalue" do
    assert_difference('Categoricvalue.count', -1) do
      delete :destroy, :id => categoricvalues(:one).id
    end

    assert_redirected_to categoricvalues_path
  end
end
