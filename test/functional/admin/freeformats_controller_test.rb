require 'test_helper'

class Admin::FreeformatsController < ActionController::TestCase
  setup :activate_authlogic

  test "should get index" do
    login_nadrowski
    get :index
    assert_response :success
  end
  
end
