module ProjectsHelper
  def all_projects_for_select
    Project.all(:order => :shortname).collect{|p| [p.to_s, p.id]}
  end
end
