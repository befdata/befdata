require 'test_helper'

class PagesControllerTest < ActionController::TestCase
  test "should get home" do
    get :home
    assert_response :success
  end

  test "should get imprint" do
    get :imprint
    assert_response :success
  end

  test "should get help" do
    get :help
    assert_response :success
  end

  test "sould get data" do
    get :data
    assert_response :success
  end

end
