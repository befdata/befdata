class Admin::FreeformatsController < Admin::AdminController
  active_scaffold :freeformat do |config|
    config.label = "Projects"
    config.show.link = false
    # config.search.link = false
    # show config
    config.show.columns = [:id]

    # list config
    config.list.columns = [:id, :created_at, :file_file_name, :dataset_id, :paperproposal_id]
    config.list.sorting = {:id => :asc }

    [config.update, config.create].each do |c|
      c.columns = [:id]
    end
  end
end
