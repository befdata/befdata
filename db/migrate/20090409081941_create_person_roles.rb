class CreatePersonRoles < ActiveRecord::Migration
  def self.up
    create_table :person_roles do |t|
      t.integer :person_id
      t.string :person_txtid
      t.integer :project_id
      t.integer :institution_id
      t.string :role
      t.text :comment

      t.timestamps
    end
  end

  def self.down
    drop_table :person_roles
  end
end
