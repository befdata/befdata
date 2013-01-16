module AclPatch
  def users
    self.accepted_roles.includes(:users).collect{|r| r.users}.flatten
  end
  def query_by_role(rolename)
    self.accepted_roles.where(name: rolename).includes(:users).collect{|r| r.users}.flatten
  end
end