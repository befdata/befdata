require 'test_helper'

class CategoriesControllerTest < ActionController::TestCase
  setup :activate_authlogic

  test "show category" do
    login_nadrowski

    get :show, :id => 66

    assert :success
  end

end