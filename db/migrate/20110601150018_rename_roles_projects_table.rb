class RenameRolesProjectsTable < ActiveRecord::Migration
  def self.up
    rename_table('projects_roles', 'roles_projects')
  end

  def self.down
    rename_table('roles_projects', 'projects_roles')
  end
end
