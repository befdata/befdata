class Admin::RolesController < AdminBaseController
  active_scaffold :roles do |config|
    config.label = "Roledefinitions"
    config.show.link = false
    config.search.link = false

    config.columns = [:name, :authorizable_type, :authorizable_id, :authorizable]
    config.subform.columns = [:authorizable_type, :authorizable_id]
    config.columns[:authorizable_type].form_ui = :select
    config.columns[:authorizable_type].options = ["Context", "Project"]
    config.columns[:authorizable_id].form_ui = :select
    config.columns[:authorizable_id].options = Context.all.map{|e| ["Context: #{e.title}", e.id]} + Project.all.map{|e| ["Project: #{e.name}", e.id]}

    #config.columns[:authoriable].includes = [:context, :projects]
    config.list.sorting = { :name => :asc }
  end
end
