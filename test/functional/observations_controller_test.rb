require 'test_helper'

class ObservationsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:observations)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create observation" do
    assert_difference('Observation.count') do
      post :create, :observation => { }
    end

    assert_redirected_to observation_path(assigns(:observation))
  end

  test "should show observation" do
    get :show, :id => observations(:one).id
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => observations(:one).id
    assert_response :success
  end

  test "should update observation" do
    put :update, :id => observations(:one).id, :observation => { }
    assert_redirected_to observation_path(assigns(:observation))
  end

  test "should destroy observation" do
    assert_difference('Observation.count', -1) do
      delete :destroy, :id => observations(:one).id
    end

    assert_redirected_to observations_path
  end
end
