require 'test_helper'

class PaperproposalsControllerTest < ActionController::TestCase
  setup :activate_authlogic

  test "should get index" do
    login_nadrowski
    get :index
    assert_response :success
  end

  test "without login should not show the index and should redirect to login" do
    get :index
    assert_redirected_to :login
  end

  
end
