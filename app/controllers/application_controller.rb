class ::ApplicationController < ActionController::Base
  protect_from_forgery

  helper_method :current_user_session, :current_user

  layout :layout_from_config

protected
  def layout_from_config
    layout = ActiveRecord::Base.configurations[::Rails.env]["layout"]
    case layout
      when "fundiv" then
        "fundiv"
      else
        "application"
    end

  end

private
  def current_user_session
    return @current_user_session if defined?(@current_user_session)
    @current_user_session = UserSession.find
  end

  def current_user
    return @current_user if defined?(@current_user)
    @current_user = current_user_session && current_user_session.user
  end

  def require_user
    unless current_user
      store_location
      flash[:notice] = "You must be logged in to access this page"
      redirect_to new_user_session_url
      return false
    end
  end

  def require_no_user
    if current_user
      store_location
      flash[:notice] = "You must be logged out to access this page"
      redirect_to account_url
      return false
    end
  end

  def store_location
    session[:return_to] = request.request_uri
  end

  def redirect_back_or_default(default)
    redirect_to(session[:return_to] || default)
    session[:return_to] = nil
  end

  def current_cart
    cookies[:cart_id] ||= Cart.create!.id
    begin
      @current_cart ||= Cart.find(cookies[:cart_id])
    rescue
      cookies[:cart_id] = Cart.create!.id
      @current_cart ||= Cart.find(cookies[:cart_id])
    end

  end

end
