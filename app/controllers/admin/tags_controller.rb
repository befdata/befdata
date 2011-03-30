class Admin::TagsController < Admin::AdminController
    active_scaffold :tag do |config|
      config.label = "Tags"
      config.show.link = false
      config.search.link = false

      config.show.columns = [:name, :kind]

      [config.update, config.create].each do |c|
          c.columns = [:name, :kind]
      end
    end
end
