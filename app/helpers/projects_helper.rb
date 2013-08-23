module ProjectsHelper
  def all_projects_for_select
    Project.select('id, name').order('lower(name)').collect{|p| [p.to_s, p.id]}
  end
end
