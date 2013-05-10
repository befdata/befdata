require 'test_helper'

class NotificationMailerTest < ActionMailer::TestCase
  test "data request rejected" do
    old_notification_count = Notification.count
    NotificationMailer.data_request_rejected(Paperproposal.first)

    assert_true Notification.count > old_notification_count
  end
end
