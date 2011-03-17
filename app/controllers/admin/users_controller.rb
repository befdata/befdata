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

    config.columns << :add_role
    config.columns[:add_role].label = "Add Role"
    
    # show config
    config.show.columns = [:firstname, :middlenames, :lastname, :salutation, :comment, :role_objects, :email]

    # list config
    config.columns = [:firstname, :lastname, :role_objects]
    config.list.sorting = { :lastname => :asc }

    [config.update, config.create].each do |c|
      c.columns = [:firstname, :middlenames, :lastname, :salutation,
        :login, :password, :password_confirmation, :comment, :email, :add_role]
    end

    config.subform.layout = :vertical
  end
end


