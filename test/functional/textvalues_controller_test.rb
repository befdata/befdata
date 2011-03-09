require 'test_helper'

class TextvaluesControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:textvalues)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create textvalue" do
    assert_difference('Textvalue.count') do
      post :create, :textvalue => { }
    end

    assert_redirected_to textvalue_path(assigns(:textvalue))
  end

  test "should show textvalue" do
    get :show, :id => textvalues(:one).id
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => textvalues(:one).id
    assert_response :success
  end

  test "should update textvalue" do
    put :update, :id => textvalues(:one).id, :textvalue => { }
    assert_redirected_to textvalue_path(assigns(:textvalue))
  end

  test "should destroy textvalue" do
    assert_difference('Textvalue.count', -1) do
      delete :destroy, :id => textvalues(:one).id
    end

    assert_redirected_to textvalues_path
  end
end
