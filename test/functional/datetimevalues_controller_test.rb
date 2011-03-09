require 'test_helper'

class DatetimevaluesControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:datetimevalues)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create datetimevalue" do
    assert_difference('Datetimevalue.count') do
      post :create, :datetimevalue => { }
    end

    assert_redirected_to datetimevalue_path(assigns(:datetimevalue))
  end

  test "should show datetimevalue" do
    get :show, :id => datetimevalues(:one).id
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => datetimevalues(:one).id
    assert_response :success
  end

  test "should update datetimevalue" do
    put :update, :id => datetimevalues(:one).id, :datetimevalue => { }
    assert_redirected_to datetimevalue_path(assigns(:datetimevalue))
  end

  test "should destroy datetimevalue" do
    assert_difference('Datetimevalue.count', -1) do
      delete :destroy, :id => datetimevalues(:one).id
    end

    assert_redirected_to datetimevalues_path
  end
end
