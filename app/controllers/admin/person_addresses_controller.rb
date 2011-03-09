class Admin::PersonAddressesController < AdminBaseController
  
  active_scaffold :person_addresses do |config|
    config.label = "Adressen"
    config.show.link = false
    config.search.link = false

    config.list.columns = [:person, :phone, :email]
    config.list.sorting = { :person => :asc }
    config.update.columns = [:phone, :email, :url, :comment]
    config.create.columns = [:person, :phone, :email, :url, :comment]

    config.columns[:person].form_ui = :select
    
    config.subform.layout = :vertical
  end
end
