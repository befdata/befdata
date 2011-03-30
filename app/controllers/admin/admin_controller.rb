class Admin::AdminController < ApplicationController
  layout 'admin'

  access_control do
    allow :admin
  end
end