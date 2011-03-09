class RefactorRoles < ActiveRecord::Migration
  def self.up
    rename_column :person_roles, :role, :role_old
    add_column :person_roles, :role_id, :integer
  end

  def self.down
    remove_column :person_roles, :role_id
    rename_column :person_roles, :role_old, :role
  end
end
