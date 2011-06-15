require 'test_helper'
require 'authlogic/test_case'

class PaperproposalsControllerTest < ActionController::TestCase
  setup :activate_authlogic

  test "should get index" do
    login_nadrowski
    get :index
    assert_response :success
  end

  
end
