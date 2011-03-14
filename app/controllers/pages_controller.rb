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


    @tags = Tag.find(:all, :order => :name)
    @datasets = DataSet.find(:all, :order => :title)
    
  end

end
