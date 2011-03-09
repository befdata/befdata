class Admin::ProjectsController < AdminBaseController
  active_scaffold :project do |config|
    config.label = "Projekte"
    config.show.link = false
    config.search.link = false

    # show config
    config.show.columns = [:shortname, :name, :description, 
                           :funding, :comment]
    
    # list config
    config.list.columns = [:id, :shortname, :name]
    config.list.sorting = { :shortname => :asc }

    [config.update, config.create].each do |c|
      c.columns = [:shortname, :name, :description, :funding, :comment]
    end
  end
  
end
