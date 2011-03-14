class PagesController < ApplicationController
  def home
  end

  def impressum
  end

  def help
  end

  # This method is the dashboard method of our Portal
  # This provide a first look to our metadata and give a hint about our data
  def data

    @file = Filevalue.new

    @tags = Tag.find(:all, :order => :name)
    @datasets = DataSet.find(:all, :order => :title)
    
  end

  def show_tags
    @tags = Tag.find(:all, :order => :name, :include => :taggings )
  end

end
