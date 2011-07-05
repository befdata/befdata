class Admin::CategoricvaluesController < Admin::AdminController
    active_scaffold :categoricvalue do |config|
      config.label = "Categoric Values"

      config.show.link = false
      config.delete.link = false
      config.search.link = false
      config.update.link.label = "Edit Categoric Value"

      config.list.columns = [:id, :short, :long, :tags, :sheetcells, :import_categoricvalues]

      config.list.per_page = 1000

      config.create.columns = [:short, :long, :description, :comment, :tags]

      config.update.columns = [:id, :short, :long, :description, :comment, :tags,
                              :sheetcells, :import_categoricvalues]

    end
end
