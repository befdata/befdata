class Admin::DatasetsController < Admin::AdminController
  #protect_from_forgery :only => [:create, :update, :delete]
  
  active_scaffold :dataset do |config|
    config.label = "DataSets"

    config.create.link = false
    config.update.link.label = "Edit Data set"

    config.list.columns = [:id, :title, :filename, :downloads]

    [config.update, config.show].each do |c|
      c.columns =  [:title, :visible_for_public, :free_for_public, :free_for_members, :free_within_projects,
                   :filename,
                   :abstract, :comment, :usagerights,
                   :published, :spatialextent, :datemin, :datemax,
                   :temporalextent, :taxonomicextent, :design,
                   :dataanalysis, :circumstances]
    end
    config.show.columns << :freeformats

  end
end
