class PagesController < ApplicationController

  skip_before_filter :deny_access_to_all
  access_control do
    actions :home, :imprint, :help, :data do
      allow all
    end
  end

  def home
  end

  def imprint
  end

  def help
  end

  # This method is the dashboard method of our Portal
  # This provide a first look to our metadata and give a hint about our data
  def data
    @file = Datafile.new
    @freeformat = Freeformat.new

    @tags = Tag.order(:name)
    @datasets = Dataset.order(:title)
  end

end
