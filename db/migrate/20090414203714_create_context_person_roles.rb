class CreateContextPersonRoles < ActiveRecord::Migration
  def self.up
    create_table :context_person_roles do |t|
      t.integer :context_id
      t.integer :person_role_id
      t.text :comment

      t.timestamps
    end
  end

  def self.down
    drop_table :context_person_roles
  end
end
