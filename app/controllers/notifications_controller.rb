class NotificationsController < ApplicationController
  skip_before_filter :deny_access_to_all
  before_filter :load_notification, :except => [:index]
  access_control do
    allow logged_in, to: :index
    actions :mark_as_read, :destroy do
      allow logged_in, :if => :notification_belongs_user?
    end
  end

  def index
    @notifications = current_user.notifications.order('created_at DESC')
  end

  def mark_as_read
    if defined?(params[:read]) && @notification.update_attribute(:read, params[:read])
      redirect_to notifications_url
    else
      redirect_to notifications_url, alert: 'Error'
    end
  end

  def destroy
    @notification.destroy
    redirect_to notifications_url
  end

private

  def load_notification
    @notification = Notification.find params[:id]
  end

  def notification_belongs_user?
    defined?(current_user) && defined?(@notification) && current_user == @notification.user
  end
end
