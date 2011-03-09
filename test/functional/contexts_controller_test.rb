require 'test_helper'

class ContextsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:contexts)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create context" do
    assert_difference('Context.count') do
      post :create, :context => { }
    end

    assert_redirected_to context_path(assigns(:context))
  end

  test "should show context" do
    get :show, :id => contexts(:one).id
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => contexts(:one).id
    assert_response :success
  end

  test "should update context" do
    put :update, :id => contexts(:one).id, :context => { }
    assert_redirected_to context_path(assigns(:context))
  end

  test "should destroy context" do
    assert_difference('Context.count', -1) do
      delete :destroy, :id => contexts(:one).id
    end

    assert_redirected_to contexts_path
  end
end
