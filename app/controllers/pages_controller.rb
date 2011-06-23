class PagesController < ApplicationController

  skip_before_filter :deny_access_to_all
  access_control do
    actions :home, :impressum, :help, :data do
      allow all
    end
  end

  def home
  end

  def impressum
  end

  def help
  end

  # This method is the dashboard method of our Portal
  # This provide a first look to our metadata and give a hint about our data
  def data

    @file = Datafile.new
    @freeformat = Freeformat.new

    @tags = Tag.find(:all, :order => :name)
    @datasets = Dataset.where(:destroy_me => false).order(:title)
    
  end

  #TODO This Action is not used see #4668
  def show_tags
    @tags = Tag.find(:all, :order => :name, :include => :taggings )
  end

end
