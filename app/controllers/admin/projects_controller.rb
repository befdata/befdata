class Admin::ProjectsController < Admin::AdminController
    active_scaffold :project do |config|
    config.label = "Projects"
    config.show.link = false
    # config.search.link = false
    # show config
    config.show.columns = [:shortname, :name, :description, :comment]

    # list config
    config.list.columns = [:id, :shortname, :name]
    config.list.sorting = { :shortname => :asc }

    [config.update, config.create].each do |c|
      c.columns = [:shortname, :name, :description,
                   :comment, :accepted_roles]
      #c.columns = [:shortname, :name, :description,
      #             :comment]
    end
  end
end
