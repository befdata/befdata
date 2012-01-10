class Admin::TagsController < Admin::AdminController
    active_scaffold 'ActsAsTaggableOn::Tag' do |config|
      config.label = "Tags"
      config.show.link = false

      config.list.columns = [:id, :name, :taggings]

      [config.update, config.create].each do |c|
          c.columns = [:name]
      end
    end
end
