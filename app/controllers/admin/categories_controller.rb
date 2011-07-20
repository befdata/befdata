class Admin::CategoriesController < Admin::AdminController
    active_scaffold :category do |config|
      config.label = "Categories"

      config.show.link = false
      config.delete.link = false
      config.search.link = false
      config.update.link.label = "Edit Category"

      config.list.columns = [:description, :long,
                             :short, :comment, :tags]

      config.list.per_page = 1000

      config.create.columns = [:description, :long,
                             :short, :comment, :tags]

      config.update.columns = [:description, :long,
                             :short, :comment, :tags,
                             :sheetcells, :import_categories]
        # config.columns[:methodstep].collapsed = true
    end
end
