class Admin::AdminController < ApplicationController
  layout 'admin'

  skip_before_filter :deny_access_to_all
  access_control :admin_only_acl do
    allow :admin
  end

end