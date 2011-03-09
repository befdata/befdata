class Admin::PersonRolesController < AdminBaseController
  
  active_scaffold :person_roles do |config|
    config.label = "People and their roles in projects"
    config.show.link = false
    config.search.link = false


    config.columns = [:person, :project, :institution, :role, :comment]
    config.list.columns.exclude :comment, :institution
    config.list.sorting = { :person => :asc }
    config.list.per_page = 1000

    config.columns[:person].form_ui = :select
    config.columns[:project].form_ui = :select
    config.columns[:institution].form_ui = :select
    config.columns[:role].form_ui = :select
   
  end
end
