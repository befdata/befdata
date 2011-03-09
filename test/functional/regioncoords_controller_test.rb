require 'test_helper'

class RegioncoordsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:regioncoords)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create regioncoord" do
    assert_difference('Regioncoord.count') do
      post :create, :regioncoord => { }
    end

    assert_redirected_to regioncoord_path(assigns(:regioncoord))
  end

  test "should show regioncoord" do
    get :show, :id => regioncoords(:one).id
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => regioncoords(:one).id
    assert_response :success
  end

  test "should update regioncoord" do
    put :update, :id => regioncoords(:one).id, :regioncoord => { }
    assert_redirected_to regioncoord_path(assigns(:regioncoord))
  end

  test "should destroy regioncoord" do
    assert_difference('Regioncoord.count', -1) do
      delete :destroy, :id => regioncoords(:one).id
    end

    assert_redirected_to regioncoords_path
  end
end
