require 'test_helper'

class ObservationsMeasurementsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:observations_measurements)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create observations_measurement" do
    assert_difference('ObservationsMeasurement.count') do
      post :create, :observations_measurement => { }
    end

    assert_redirected_to observations_measurement_path(assigns(:observations_measurement))
  end

  test "should show observations_measurement" do
    get :show, :id => observations_measurements(:one).id
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => observations_measurements(:one).id
    assert_response :success
  end

  test "should update observations_measurement" do
    put :update, :id => observations_measurements(:one).id, :observations_measurement => { }
    assert_redirected_to observations_measurement_path(assigns(:observations_measurement))
  end

  test "should destroy observations_measurement" do
    assert_difference('ObservationsMeasurement.count', -1) do
      delete :destroy, :id => observations_measurements(:one).id
    end

    assert_redirected_to observations_measurements_path
  end
end
