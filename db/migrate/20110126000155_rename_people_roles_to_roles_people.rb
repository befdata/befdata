class RenamePeopleRolesToRolesPeople < ActiveRecord::Migration
  def self.up
    rename_table :people_roles, :roles_people
  end

  def self.down
    rename_table :roles_people, :people_roles
  end
end
