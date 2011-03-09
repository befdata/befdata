require 'test_helper'

class MeasurementsMethodstepsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:measurements_methodsteps)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create measurements_methodsteps" do
    assert_difference('MeasurementsMethodsteps.count') do
      post :create, :measurements_methodsteps => { }
    end

    assert_redirected_to measurements_methodsteps_path(assigns(:measurements_methodsteps))
  end

  test "should show measurements_methodsteps" do
    get :show, :id => measurements_methodsteps(:one).id
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => measurements_methodsteps(:one).id
    assert_response :success
  end

  test "should update measurements_methodsteps" do
    put :update, :id => measurements_methodsteps(:one).id, :measurements_methodsteps => { }
    assert_redirected_to measurements_methodsteps_path(assigns(:measurements_methodsteps))
  end

  test "should destroy measurements_methodsteps" do
    assert_difference('MeasurementsMethodsteps.count', -1) do
      delete :destroy, :id => measurements_methodsteps(:one).id
    end

    assert_redirected_to measurements_methodsteps_path
  end
end
