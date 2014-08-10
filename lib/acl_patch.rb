module AclPatch
  def get_user_with_role(rolename)
    User.joins('join roles_users on roles_users.user_id = users.id join roles on roles.id = roles_users.role_id')
        .where(["roles.authorizable_type = ? and roles.authorizable_id = ? and roles.name = ?", self.class.base_class.name, self.id, rolename.to_s])
  end
  def set_user_with_role(rolename, people)
    people  = [people] unless people.is_a?(Array)
    current = self.get_user_with_role(rolename)
    people.each {|u| u.has_role!(rolename, self) unless current.include?(u)}
    current.each {|u| u.has_no_role!(rolename, self) unless people.include?(u)}
  end
end