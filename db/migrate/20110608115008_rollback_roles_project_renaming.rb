class RollbackRolesProjectRenaming < ActiveRecord::Migration
  def self.up
    rename_table('roles_projects', 'projects_roles')
  end

  def self.down
    rename_table('projects_roles', 'roles_projects')
  end
end