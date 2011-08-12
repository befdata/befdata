class Admin::TagsController < Admin::AdminController
    active_scaffold :tag do |config|
      config.label = "Tags"
      config.show.link = false

      config.list.columns = [:id, :name, :kind, :taggings]

      [config.update, config.create].each do |c|
          c.columns = [:name, :kind]
      end
    end
end
