require 'test_helper'

class ContextFreepeopleControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:context_freepeople)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create context_freeperson" do
    assert_difference('ContextFreeperson.count') do
      post :create, :context_freeperson => { }
    end

    assert_redirected_to context_freeperson_path(assigns(:context_freeperson))
  end

  test "should show context_freeperson" do
    get :show, :id => context_freepeople(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => context_freepeople(:one).to_param
    assert_response :success
  end

  test "should update context_freeperson" do
    put :update, :id => context_freepeople(:one).to_param, :context_freeperson => { }
    assert_redirected_to context_freeperson_path(assigns(:context_freeperson))
  end

  test "should destroy context_freeperson" do
    assert_difference('ContextFreeperson.count', -1) do
      delete :destroy, :id => context_freepeople(:one).to_param
    end

    assert_redirected_to context_freepeople_path
  end
end
