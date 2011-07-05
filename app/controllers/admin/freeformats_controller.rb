class Admin::FreeformatsController < Admin::AdminController
  active_scaffold :freeformat do |config|
    config.label = "Freeformats"

    config.show.columns = [:id, :file_file_name, :description, :created_at, :updated_at,
                           :dataset_id, :paperproposal_id]

    config.list.columns = [:id, :created_at, :file_file_name, :dataset_id, :paperproposal_id]
    config.list.sorting = {:id => :asc }

    [config.update, config.create].each do |c|
      c.columns = [:file, :description, :dataset_id, :paperproposal_id]
    end
  end
end
