class RemoveProjectRoles < ActiveRecord::Migration
  def self.up
    drop_table :projects_roles
  end

  def self.down
    create_table "projects_roles", :id => false, :force => true do |t|
      t.integer  "project_id"
      t.integer  "role_id"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "projects_roles", ["project_id", "role_id"], :name => "index_projects_roles_on_project_id_and_role_id"
  end
end
