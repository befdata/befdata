class Admin::DatagroupsController < Admin::AdminController
  active_scaffold :datagroup do |config|
    config.label = "Datagroups"

    config.show.link = false

    config.search.columns = [:id, :title, :description]

    config.list.columns = [:id, :title, :description, :datacolumns]
    config.list.per_page = 1000

    config.update.columns = [:id, :title, :description, :instrumentation,
                             :informationsource,
                             :methodvaluetype, :timelatency,
                             :timelatencyunit, :comment, :datacolumns]

    config.subform.layout = :vertical

    #config.action_links.add 'Delete'

    config.delete.link.ignore_method = :has_datacolumns?

  end

private

  # A workaround to not show delete links fur datagroups with linked datacolumns.
  # It would be cleaner to declare the following in the model:
  #   def authorized_for_delete?
  #     datacolumns.size > 0 ? true : false
  #   end
  # But up to now there is a bug in AS which displays escaped html instead of an inactive Delete-link.
  def has_datacolumns? (record)
    record.datacolumns.size > 0 ? true : false
  end

end
