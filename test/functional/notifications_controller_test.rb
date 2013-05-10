require 'test_helper'

class NotificationsControllerTest < ActionController::TestCase
  setup :activate_authlogic

  test "should get index" do
    login_nadrowski
    get :index, :user => User.find(1)
    assert_success_no_error
    assert_not_nil assigns(:notifications)
  end

  test "should mark as read" do
    pending "TODO, create fixtures"
  end

  test "should destroy notification" do
    pending "TODO, create fixtures"
    #assert_difference('Notification.count', -1) do
    #  delete :destroy, id: @notification
    #end
    #
    #assert_redirected_to notifications_path
  end
end
