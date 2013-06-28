module DatagroupsHelper
  def sortable(column, title = nil)
    title ||= column.titleize
    css_class = column == params[:sort] ? params[:direction] : nil
    direction = column == params[:sort] && params[:direction] == "asc" ? "desc" : "asc"
    link_to title, {:sort => column, :direction => direction, :search => params[:search]}, {:class => css_class}
  end

  def dropdown_list_to_sort_datagroups
    options_for_select({
      "Title" => datagroups_path(params.merge(sort: 'title', direction: 'asc')),
      "Recently Added" => datagroups_path(params.merge(sort: 'created_at', direction: 'desc')),
      "Most used" => datagroups_path(params.merge(sort: 'datacolumns_count', direction: 'desc')),
      "Least Used" => datagroups_path(params.merge(sort: 'datacolumns_count', direction: 'asc'))
      }, selected: datagroups_path(params))
  end
end