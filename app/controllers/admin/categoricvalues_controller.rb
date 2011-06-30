class Admin::CategoricvaluesController < Admin::AdminController
    active_scaffold :categoricvalue do |config|
      config.label = "Categoric Values"

      config.show.link = false
      config.delete.link = false
      config.search.link = false
      config.update.link.label = "Edit Categoric Value"

      config.list.columns = [:id, :description, :long,
                             :short, :comment, :tags, :links]

      config.list.per_page = 1000

      config.create.columns = [:description, :long,
                             :short, :comment, :tags]

      config.update.columns = [:id, :description, :long,
                             :short, :comment, :tags, :sheetcells, :import_categoricvalues]

        # config.columns[:methodstep].collapsed = true
    end
end
