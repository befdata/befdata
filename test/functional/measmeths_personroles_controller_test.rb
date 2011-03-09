require 'test_helper'

class MeasmethsPersonrolesControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:measmeths_personroles)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create measmeths_personrole" do
    assert_difference('MeasmethsPersonrole.count') do
      post :create, :measmeths_personrole => { }
    end

    assert_redirected_to measmeths_personrole_path(assigns(:measmeths_personrole))
  end

  test "should show measmeths_personrole" do
    get :show, :id => measmeths_personroles(:one).id
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => measmeths_personroles(:one).id
    assert_response :success
  end

  test "should update measmeths_personrole" do
    put :update, :id => measmeths_personroles(:one).id, :measmeths_personrole => { }
    assert_redirected_to measmeths_personrole_path(assigns(:measmeths_personrole))
  end

  test "should destroy measmeths_personrole" do
    assert_difference('MeasmethsPersonrole.count', -1) do
      delete :destroy, :id => measmeths_personroles(:one).id
    end

    assert_redirected_to measmeths_personroles_path
  end
end
