module AclPatch
  def users
    self.accepted_roles.includes(:users).collect{|r| r.users}.flatten
  end
  def get_user_with_role(rolename)
    self.accepted_roles.where(name: rolename).includes(:users).collect{|r| r.users}.flatten
  end
  def set_user_with_role(rolename, people)
    people  = [people] unless people.is_a?(Array)
    current = self.get_user_with_role(rolename)
    people.each {|u| u.has_role!(rolename, self) unless current.include?(u)}
    current.each {|u| u.has_no_role!(rolename, self) unless people.include?(u)}
  end
end