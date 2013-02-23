module DatagroupsHelper
  def sortable(column, title = nil)
    title ||= column.titleize
    css_class = column == params[:sort] ? params[:direction] : nil
    direction = column == params[:sort] && params[:direction] == "asc" ? "desc" : "asc"
    link_to title, {:sort => column, :direction => direction, :search => params[:search]}, {:class => css_class}
  end
end