class AddRoleTable < ActiveRecord::Migration
  def self.up
    create_table :roles do |t|
      t.string :name

      t.timestamps
    end
  end

  def self.down
    remove_table :roles
  end
end
