class Admin::UsersController < Admin::AdminController


  active_scaffold :user do |config|
    config.label = "Associated people"
    #config.show.link = false
    ## config.search.link = false
    config.search.columns = [:firstname, :lastname]

    config.columns << :password
    config.columns[:password].label = "New Password<br/>(Leave this blank to keep old password)"
    config.columns[:password].form_ui = :password
    config.columns << :password_confirmation
    config.columns[:password_confirmation].label = "New Password Confirmation"
    config.columns[:password_confirmation].form_ui = :password

    # show config
    config.show.columns = [:firstname, :middlenames, :lastname, :salutation, :comment, :roles_without_objects, :roles_with_objects, :email]

    # list config
    config.columns = [:avatar, :firstname, :lastname, :roles_without_objects, :roles_with_objects]
    config.list.sorting = { :lastname => :asc }

    [config.update, config.create].each do |c|
      c.columns = [:firstname, :middlenames, :lastname, :salutation,
        :login, :password, :password_confirmation, :comment,
        :url, :email,
        :institution_name, :institution_url,
        :institution_phone, :institution_fax,
        :street, :city, :country,
        :admin, :project_board, :avatar]
    end

    config.subform.layout = :vertical

    #for the avatar-imapge upload
    config.create.multipart = true
    config.update.multipart = true
    ActiveScaffold::Bridges::Paperclip::Lib::PaperclipBridgeHelpers.thumbnail_style=:small
  end

end


