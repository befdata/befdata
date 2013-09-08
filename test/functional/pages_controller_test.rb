require 'test_helper'

class PagesControllerTest < ActionController::TestCase
  test "should get home" do
    get :home
    assert_success_no_error
  end

  test "should get imprint" do
    get :imprint
    assert_success_no_error
  end

  test "sould get data" do
    get :data
    assert_success_no_error
  end

end
