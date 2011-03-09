# This controller handles all incoming calls that would not result in calling any other action.

class PagesController < ApplicationController
  
  # The index method renders the default page named "welcome". 
  def index
    welcome
  end
  
  # The method_missing action is called whenever an unknown action is called. As this might be a call for a specific page, the database is queried for the pagename.
  # If no page is found, a "Page not found" error is issued. 
  def method_missing(method_id, *args, &block)
    @page = Page.find(:first, :conditions => [ "title = ?", method_id.to_s])
    if @page == nil
      @page = Page.new :content => "<h1>Error 404: Page not found!</h1><p>Page not found!</p>"
    end
    if @page.content == nil
      @page.content = ""
    end
    render :template => "pages/index"
  end
end

