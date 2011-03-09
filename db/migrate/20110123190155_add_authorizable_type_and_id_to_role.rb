class AddAuthorizableTypeAndIdToRole < ActiveRecord::Migration
  def self.up
    add_column :roles, :authorizable_type, :string, :limit => 40
    add_column :roles, :authorizable_id, :integer
  end

  def self.down
    remove_column :roles, :authorizable_type
    remove_column :roles, :authorizable_id
  end
end
