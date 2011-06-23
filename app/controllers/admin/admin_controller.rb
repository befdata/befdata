class Admin::AdminController < ApplicationController
  layout 'admin'

  skip_before_filter :deny_access_to_all
  access_control do
    allow :admin
  end
end