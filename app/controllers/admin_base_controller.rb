class AdminBaseController < ApplicationController
  # Comment the following line to get unauthorized access to the
  # administration backend.
  before_filter :authorized?

  def index
    # Unspecific calls of the admin backend redirect to a standard page
    redirect_to :controller => admin_root_path and return
  end

  protected
  
  def authorized?
    # Only users with a valid session cookie may access the admin backend. 
    redirect_to login_path and return unless logged_in?
  end
end
