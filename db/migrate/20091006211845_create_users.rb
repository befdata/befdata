class CreateUsers < ActiveRecord::Migration
  def self.up
    add_column :people, :login,                     :string, :limit => 40
    add_column :people, :crypted_password,          :string, :limit => 40
    add_column :people, :salt,                      :string, :limit => 40
    add_column :people, :remember_token,            :string, :limit => 40
    add_column :people, :remember_token_expires_at, :datetime
  end

  def self.down
    remove_column :people, :login
    remove_column :people, :crypted_password
    remove_column :people, :salt
    remove_column :people, :remember_token
    remove_column :people, :remember_token_expires_at
  end
end
