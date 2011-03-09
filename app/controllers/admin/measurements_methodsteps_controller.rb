class Admin::MeasurementsMethodstepsController < AdminBaseController
  active_scaffold :measurements_methodstep do |config|
    config.label = "Sub-method"

    config.show.link = false
    config.delete.link = false
    config.search.link = false
    config.update.link.label = "Edit sub-method"

    config.list.columns = [:columnheader, :definition,
                           :context_id, :columnnr]
    config.list.per_page = 1000
    # default sorting: ascending on the title column
    config.list.sorting = { :columnnr => :asc }
    config.update.columns = [:columnheader, :definition, :columnnr,
                             :unit, :missingcode, :comment, 
                             :methodstep_id, :context_id, :measmeths_personroles]
    # config.columns[:methodstep].collapsed = true

  end
  


end
