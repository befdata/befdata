# This controller handles all incoming calls for data selection. 

class DataController < ApplicationController

  # The index action renders the page where every user may search
  # through the available data.
  def index
    # First of all, fetch the content of the download page from the
    # database. This allows for a free text field on top of the
    # download forms.
    @page = Page.find(:first, :conditions => [ "title = ?", "downloads" ])
    if @page == nil
      @page = Page.new :content => ""
    end
    if @page.content == nil
      @page.content = ""
    end


    # providing a new filevalue

    @tags = Tag.find(:all, :order => :name)
    

    # all data sets
    @datasets = Context.find(:all, :order => :title)
  end
  
  def show_tags
    @tags = Tag.find(:all, :order => :name, :include => :taggings )
  end 


  # Handles incoming search querys
  def search
    @query = params[:q]
    @results = ActsAsFerret::find(@query || "search", [Context])
  end  
end

