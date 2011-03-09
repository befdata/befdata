class Admin::ContextPersonRolesController < AdminBaseController
  protect_from_forgery :only => [:create, :update, :delete]

  active_scaffold :context_person_roles do |config|
    config.label = ""

    config.show.link = false
    config.search.link = false

    config.list.columns = [:person_role]
    config.list.per_page = 1000
    config.columns[:person_role].form_ui = :select

    config.update.columns = [:person_role, :comment]
    config.create.columns = [:person_role, :comment]

    config.subform.layout = :vertical

  end
  
end
