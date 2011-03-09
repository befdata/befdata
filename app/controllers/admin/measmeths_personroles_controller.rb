class Admin::MeasmethsPersonrolesController < AdminBaseController
  active_scaffold :measmeths_personrole do |config|
    config.label = ""

    config.show.link = false
    config.search.link = false

    config.list.columns = [:person_role]
    config.list.per_page = 1000
    config.update.columns = [:person_role, :comment]
    config.columns[:person_role].form_ui = :select

    config.delete.link = false
    config.subform.layout = :vertical
  end
  
end
