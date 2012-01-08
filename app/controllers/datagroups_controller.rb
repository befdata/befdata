class DatagroupsController < ApplicationController

  skip_before_filter :deny_access_to_all
  access_control do
    actions :index do
      allow logged_in
    end
  end

  def index
    @datagroups = Datagroup.order(:title)
  end

end