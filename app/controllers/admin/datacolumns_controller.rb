class Admin::DatacolumnsController < Admin::AdminController
  active_scaffold :datacolumn do |config|
    config.label = "Datacolumns"

    config.show.link = false
    config.delete.link = false
    config.create.link = false
    config.update.link.label = "Edit datacolumn"

    config.list.columns = [:id, :columnheader, :definition,
                           :dataset_id, :columnnr]
    config.list.per_page = 1000

    config.list.sorting = { :columnnr => :asc }

    config.update.columns = [:columnheader, :definition, :columnnr,
                             :unit, :missingcode, :comment,
                             :datagroup_id, :dataset_id]

  end
end
