class ::ApplicationController < ActionController::Base
  protect_from_forgery
  helper_method :current_user_session, :current_user
  #layout "application"

  access_control :deny_access_to_all do
    deny all
  end
  rescue_from "Acl9::AccessDenied", :with => :access_denied

  def access_denied
    if current_user
      flash[:error] = 'Access denied. You do not have the appropriate rights to perform this operation.'
      redirect_back_or_default root_url
    else
      flash[:error] = 'Access denied. Try to log in first.'
      redirect_back_or_default root_url
    end
  end

  def dataset_is_free_for_members
    return true if @dataset.free_for_members unless @dataset.blank?
    false
  end

  def dataset_is_free_for_public
    return true if @dataset.free_for_public unless @dataset.blank?
    false
  end

  def dataset_is_free_for_project_of_user (user = current_user)
    return true if (@dataset.free_within_projects && !(user.projects & @dataset.projects).empty?) unless @dataset.blank?
    false
  end


protected

  def layout_from_config
    LayoutHelper::BEF_LAYOUT
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
      flash[:error] = "You must be logged in to access this page"
      redirect_back_or_default root_url
      return false
    end
  end

  def require_no_user
    if current_user
      store_location
      flash[:error] = "You must be logged out to access this page"
      redirect_back_or_default root_url
      return false
    end
  end

  def store_location
    session[:return_to] = request.request_uri
  end

  def redirect_back_or_default (default = root_url)
    unless request.env['HTTP_REFERER'].blank?
      session[:return_to] = request.env['HTTP_REFERER']
      redirect_to :back
    else
      redirect_to default
    end
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