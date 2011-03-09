# This controller handles the login/logout function of the site.  
class SessionsController < ApplicationController
  
  # render new.rhtml
  def new
  end

  def create
    logout_keeping_session!
    user = Person.authenticate(params[:login], params[:password])
    if user
      # Protects against session fixation attacks, causes request forgery
      # protection if user resubmits an earlier form using back
      # button. Uncomment if you understand the tradeoffs.
      # reset_session
      self.current_user = user
      new_cookie_flag = (params[:remember_me] == "1")
      handle_remember_cookie! new_cookie_flag
      flash[:notice] = "Logged in successfully"
      redirect_back_or_default(root_path)
    else
      note_failed_signin
      @login       = params[:login]
      @remember_me = params[:remember_me]
      render :action => 'new'
    end
  end

  def destroy
    logout_killing_session!
    flash[:notice] = "You have been logged out."
    redirect_back_or_default(root_path)
  end

#  def method_missing(method_id, *args, &block)
#    @page = Page.find(:first, :conditions => [ "title = ?", 'welcome' ])
#    if @page == nil
#      @page = Page.new :content => "<h1>Error 404: Seite nicht gefunden!</h1><p>Seite nicht gefunden!<br/>Gesuchte Seite: #{method_id.to_s}.</p>"
#    end
#    if @page.content == nil
#      @page.content = ""
#    end
#    render :template => "pages/index"
#  end

protected
  # Track failed login attempts
  def note_failed_signin
    flash[:error] = "Couldn't log you in as '#{params[:login]}'"
    logger.warn "Failed login for '#{params[:login]}' from #{request.remote_ip} at #{Time.now.utc}"
  end
  
  def redirect_back_or_default(default)
      session[:return_to] ? redirect_to(session[:return_to]) : redirect_to(default)
      session[:return_to] = nil
    end
end
