class Admin::MethodsController < AdminBaseController
  active_scaffold :methodstep do |config|
    
    config.list.columns = [:id, :title, :description,
                           :measurements_methodsteps]

    config.update.columns = [:title, :description, :instrumentation,
                             :informationsource,
                             :methodvaluetype, :timelatency,
                             :timelatencyunit, :comment,
                             :measurements_methodsteps]
    config.create.columns = [:title, :description, :instrumentation,
                             :informationsource,
                             :methodvaluetype, :timelatency,
                             :timelatencyunit, :comment,
                             :measurements_methodsteps]
  end
  
end
