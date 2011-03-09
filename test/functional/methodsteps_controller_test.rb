require 'test_helper'

class MethodstepsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:methodsteps)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create methodstep" do
    assert_difference('Methodstep.count') do
      post :create, :methodstep => { }
    end

    assert_redirected_to methodstep_path(assigns(:methodstep))
  end

  test "should show methodstep" do
    get :show, :id => methodsteps(:one).id
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => methodsteps(:one).id
    assert_response :success
  end

  test "should update methodstep" do
    put :update, :id => methodsteps(:one).id, :methodstep => { }
    assert_redirected_to methodstep_path(assigns(:methodstep))
  end

  test "should destroy methodstep" do
    assert_difference('Methodstep.count', -1) do
      delete :destroy, :id => methodsteps(:one).id
    end

    assert_redirected_to methodsteps_path
  end
end
