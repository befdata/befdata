class Admin::PeopleController < AdminBaseController
  active_scaffold :person do |config|
    config.label = "Associated people"
    #config.show.link = false
    ## config.search.link = false
    config.search.columns = [:firstname, :lastname]

    config.columns << :pwd
    config.columns[:pwd].label = "New Password<br/>(Leave this blank to keep old password)"
    config.columns[:pwd].form_ui = :password

    # show config
    config.show.columns = [:firstname, :middlenames, :lastname, :salutation, :comment, :role_objects, :person_roles]

    # list config
    config.columns = [:firstname, :lastname, :role_objects, :person_roles]
    config.list.sorting = { :lastname => :asc }

    [config.update, config.create].each do |c|
      c.columns = [:firstname, :middlenames, :lastname, :salutation,
        :login, :pwd, :comment,
        #:person_roles,
        :person_addresses
        ]
    end

    config.subform.layout = :vertical
  end
  
end
