class Admin::PagesController < AdminBaseController
  active_scaffold :pages do |config|
    config.label = "Pages on the website"
    config.show.link = false
    config.search.link = false

    config.columns = [:title, :content]
    config.list.columns.exclude :content
    config.list.sorting = { :title => :asc }
  end
end
