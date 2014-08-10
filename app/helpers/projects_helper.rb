module ProjectsHelper
  def all_projects_for_select
    Project.select('id, name').order('lower(name)').collect{|p| [p.to_s, p.id]}
  end

  def formated_role_text user, proj
    roles = user.roles_for(proj).collect do |role|
      str = user.alumni ? 'Former ' : ''
      str += t("role."+ role.name)
    end
    roles.join(', ')
  end
end
