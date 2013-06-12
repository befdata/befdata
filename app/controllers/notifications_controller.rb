class NotificationsController < ApplicationController

  before_filter :load_notification, :except => [:index]

  skip_before_filter :deny_access_to_all

  access_control do
    actions :index, :mark_as_read, :destroy do
      allow logged_in
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
    @notification = current_user.notifications.where(:id => params[:id]).first
    redirect_to :back and return unless @notification
  end

end
