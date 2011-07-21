class Admin::DatacolumnsController < Admin::AdminController
  active_scaffold :datacolumn do |config|
    config.label = "Datacolumns"

    config.show.link = false
    config.delete.link = false
    config.search.link = false
    config.update.link.label = "Edit datacolumn"

    config.list.columns = [:columnheader, :definition,
                           :dataset_id, :columnnr]
    config.list.per_page = 1000
    # default sorting: ascending on the title column
    config.list.sorting = { :columnnr => :asc }
    config.update.columns = [:columnheader, :definition, :columnnr,
                             :unit, :missingcode, :comment,
                             :datagroup_id, :dataset_id]
    # config.columns[:methodstep].collapsed = true

  end
    

end
