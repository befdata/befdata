class RemoveUnusedRoles < ActiveRecord::Migration
  def up
    to_be_deleted = Role.joins('left join roles_users on roles.id = roles_users.role_id').
        where('roles_users.role_id is NULL').pluck(:id)
    puts "#{to_be_deleted.length} role records was deleted"
    Role.delete(to_be_deleted)
  end

  def down
    # irreversible
  end
end
