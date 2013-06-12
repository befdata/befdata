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
    login_nadrowski
    n_id = 1

    get :mark_as_read, :id => n_id, :read => true

    assert_nil flash[:error]
    assert_equal Notification.find(n_id).read, true
  end

  test "should destroy notification" do
    login_nadrowski
    old_notification_count = Notification.count

    get :destroy, :id => 1

    assert_true Notification.count < old_notification_count
  end
end
