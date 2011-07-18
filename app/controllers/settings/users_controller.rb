class Settings::UsersController < Settings::SettingsController

  access_control do
    allow :admin
    allow logged_in # TODO: should this be more restrictive? how do I get the constraint and current user?
  end

  active_scaffold :user do |config|

    config.label = "Edit your Profile"
    config.actions.exclude :delete, :search, :create
    config.subform.layout = :vertical

    # password column config
    config.columns << :password
    config.columns[:password].label = "New Password<br/>(Leave this blank to keep old password)"
    config.columns[:password].form_ui = :password
    config.columns << :password_confirmation
    config.columns[:password_confirmation].label = "New Password Confirmation"
    config.columns[:password_confirmation].form_ui = :password

    # show config
    config.show.columns = [:firstname, :middlenames, :lastname, :salutation,
        :login, :password, :password_confirmation, :comment,
        :url, :email,
        :institution_name, :institution_url,
        :institution_phone, :institution_fax,
        :street, :city, :country,
        :admin, :project_board, :avatar]

    # list config
    config.columns = [:avatar, :firstname, :lastname, :roles_without_objects, :roles_with_objects]
    config.list.sorting = { :lastname => :asc }

    #Update config
    config.update.columns = [:firstname, :middlenames, :lastname, :salutation,
        :login, :password, :password_confirmation, :comment,
        :url, :email,
        :institution_name, :institution_url,
        :institution_phone, :institution_fax,
        :street, :city, :country,
        :avatar]

    # for the avatar-imapge upload
    config.update.multipart = true
    ActiveScaffold::Bridges::Paperclip::Lib::PaperclipBridgeHelpers.thumbnail_style=:small
  end

end