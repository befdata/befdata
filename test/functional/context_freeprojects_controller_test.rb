require 'test_helper'

class ContextFreeprojectsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:context_freeprojects)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create context_freeproject" do
    assert_difference('ContextFreeproject.count') do
      post :create, :context_freeproject => { }
    end

    assert_redirected_to context_freeproject_path(assigns(:context_freeproject))
  end

  test "should show context_freeproject" do
    get :show, :id => context_freeprojects(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => context_freeprojects(:one).to_param
    assert_response :success
  end

  test "should update context_freeproject" do
    put :update, :id => context_freeprojects(:one).to_param, :context_freeproject => { }
    assert_redirected_to context_freeproject_path(assigns(:context_freeproject))
  end

  test "should destroy context_freeproject" do
    assert_difference('ContextFreeproject.count', -1) do
      delete :destroy, :id => context_freeprojects(:one).to_param
    end

    assert_redirected_to context_freeprojects_path
  end
end
