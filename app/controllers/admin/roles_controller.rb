class Admin::RolesController < Admin::AdminController
  active_scaffold :roles do |config|

    config.columns[:name].form_ui = :select
    config.columns[:name].options = {:options => ["pi", "co-pi", "postdoc", "phd student"]}

  end
end
