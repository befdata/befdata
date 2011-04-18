class AddProjectsRoles < ActiveRecord::Migration
  def self.up
    create_table "projects_roles", :id => false, :force => true do |t|
      t.references  :project
      t.references  :role
      t.timestamps
    end
  end

  def self.down
    drop_table "projects_roles"
  end
end
