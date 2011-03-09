class Admin::InstitutionsController < AdminBaseController
  active_scaffold :institutions do |config|
    config.label = "Institutions"
    config.show.link = false
    config.search.link = false

    config.columns = [:name, :affiliation, :url, :email, :phone, :fax, :street, :city, :country, :comment]
    config.list.columns.exclude :url, :email, :phone, :fax, :comment, :street
    config.list.sorting = { :name => :asc }
    
  end
end
