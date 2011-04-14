class TagsController < ApplicationController

  def index
    @tags = Tag.find(:all, :order => :name)
  end

  def show
    redirect_to(:action => "index") and return if params[:id].blank?
    @tag = Tag.find(:first, :conditions => ["name = ?", params[:id]], :include => :taggings)
    return redirect_to(:action => "index", :status => :not_found) unless @tag

  end

end
