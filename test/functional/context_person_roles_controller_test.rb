require 'test_helper'

class ContextPersonRolesControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:context_person_roles)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create context_person_role" do
    assert_difference('ContextPersonRole.count') do
      post :create, :context_person_role => { }
    end

    assert_redirected_to context_person_role_path(assigns(:context_person_role))
  end

  test "should show context_person_role" do
    get :show, :id => context_person_roles(:one).id
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => context_person_roles(:one).id
    assert_response :success
  end

  test "should update context_person_role" do
    put :update, :id => context_person_roles(:one).id, :context_person_role => { }
    assert_redirected_to context_person_role_path(assigns(:context_person_role))
  end

  test "should destroy context_person_role" do
    assert_difference('ContextPersonRole.count', -1) do
      delete :destroy, :id => context_person_roles(:one).id
    end

    assert_redirected_to context_person_roles_path
  end
end
