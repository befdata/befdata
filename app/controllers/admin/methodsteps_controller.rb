class Admin::MethodstepsController < AdminBaseController
  active_scaffold :methodstep do |config|
    config.label = ""

    config.show.link = false
    config.search.link = false

    config.list.columns = [:id, :title, :description]
    config.list.per_page = 1000
    config.update.columns = [:id, :title, :description, :instrumentation,
                             :informationsource,
                             :methodvaluetype, :timelatency,
                             :timelatencyunit, :comment]

    config.delete.link = false

    config.subform.layout = :vertical
  end
  
end
