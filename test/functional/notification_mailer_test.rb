require 'test_helper'

class NotificationMailerTest < ActionMailer::TestCase
  test "data request rejected" do
    old_notification_count = Notification.count
    NotificationMailer.data_request_rejected(Paperproposal.first)

    assert_true Notification.count > old_notification_count
  end

  test "auto_accept_for_free_datasets" do
    old_notification_count = Notification.count

    NotificationMailer.auto_accept_for_free_datasets(User.first, Paperproposal.first)

    assert_true Notification.count > old_notification_count
  end
end
