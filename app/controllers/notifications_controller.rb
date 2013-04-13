class NotificationsController < ApplicationController

  skip_before_filter :deny_access_to_all

  access_control do
    allow all, :to => [:index, :show, :mark_as_read, :destroy]
  end


  def index
    @notifications = Notification.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @notifications }
    end
  end

  def show
    @notification = Notification.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @notification }
    end
  end

  def mark_as_read
    @notification = Notification.find(params[:id])

    respond_to do |format|
      if @notification.update_attribute(:read, params[:read])
        format.html { redirect_to @notification, notice: 'Notification was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { redirect_to @notification, :alert =>  'Error'}
        format.json { render json: @notification.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @notification = Notification.find(params[:id])
    @notification.destroy

    respond_to do |format|
      format.html { redirect_to notifications_url }
      format.json { head :no_content }
    end
  end
end
