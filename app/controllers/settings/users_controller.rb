class Settings::UsersController < Admin::UsersController
  skip_before_filter :admin_only_acl

  access_control do
    allow :admin
    allow logged_in # TODO: should this be more restrictive? how do I get the constraint and current user?
  end

  active_scaffold :user do |config|

    config.label = "Your Profile"

    config.actions.exclude :delete, :search, :create

    config.show.columns << :admin
    config.show.columns << :project_board

    config.update.columns = [:firstname, :middlenames, :lastname, :salutation,
        :login, :password, :password_confirmation, :comment,
        :url, :email,
        :institution_name, :institution_url,
        :institution_phone, :institution_fax,
        :street, :city, :country,
        :avatar]
  end
end