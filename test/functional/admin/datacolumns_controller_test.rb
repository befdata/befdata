require 'test_helper'

class Admin::DatacolumnsControllerTest < ActionController::TestCase
  setup :activate_authlogic

  test "should get index" do
    login_nadrowski
    get :index
    assert_success_no_error
  end

  test "show edit" do
    login_nadrowski
    get :edit, :id => Datacolumn.first.id
    assert_success_no_error
  end

end
