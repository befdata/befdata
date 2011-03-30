class RemoveTimestampsFromRoles < ActiveRecord::Migration
  def self.up
    remove_columns :roles_users, :created_at, :updated_at
  end

  def self.down
  end
end
