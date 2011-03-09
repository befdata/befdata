# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  include AuthenticatedSystem

  before_filter :logged_in?

  helper :all # include all helpers, all the time

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => '96e16cc25387689d552fc6354eacd172'

  def require_user
    if current_user
      logger.debug "Benutzer"
    else
      logger.debug "Kein Benutzer"
      session[:return_to] = request.request_uri
      redirect_to :login
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
  
  # See ActionController::Base for details 
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password"). 
  # filter_parameter_logging :password

  ActiveScaffold.set_defaults do |config|
    config.security.default_permission = false
  end

end
