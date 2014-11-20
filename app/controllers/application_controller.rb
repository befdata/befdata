class ::ApplicationController < ActionController::Base
  protect_from_forgery
  helper_method :current_user_session, :current_user, :get_all_paperproposal_years
  #layout :layout_from_config

  access_control :deny_access_to_all do
    deny all
  end
  rescue_from "Acl9::AccessDenied", :with => :access_denied

  def dataset_is_free_for_members
    return true if @dataset.free_for_members? unless @dataset.blank?
    false
  end

  def dataset_is_free_for_public
    return true if @dataset.free_for_public? unless @dataset.blank?
    false
  end

  def dataset_is_free_for_project_of_user (user = current_user)
    return true if (@dataset.free_within_projects? && !(user.projects & @dataset.projects).empty?) unless @dataset.blank?
    false
  end

  def get_all_paperproposal_years
    years = Paperproposal.pluck(:created_at).map(&:year)
    years.uniq.sort.reverse
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

  def require_no_user
    if current_user
      flash[:error] = "You must be logged out to access this page"
      redirect_back_or_default root_url
      return false
    end
  end

  def redirect_back_or_default (default = root_url)
    unless request.env['HTTP_REFERER'].blank?
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

  # specify a collection of sorted-by options, and one of them is the default
  # eg: validate_sort_params(collection: ['a', 'b'], default: 'a')
  def validate_sort_params(*options)
    options = options.extract_options!
    raise 'A collection of allowed sorting options should be specified!' unless options[:collection].present?
    options[:default] ||= options[:collection].first
    params[:sort] = options[:default] unless options[:collection].include?(params[:sort])
    params[:direction] = 'asc' unless ["desc", "asc"].include?(params[:direction])
  end

  def access_denied
    if current_user
      flash[:error] = 'Access denied. You do not have the appropriate rights to perform this operation.'
      redirect_back_or_default root_url
    else
      flash[:error] = 'Access denied. Try to log in first.'
      redirect_back_or_default root_url
    end
  end
end
