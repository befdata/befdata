class CreateProjects < ActiveRecord::Migration
  def self.up
    create_table :projects do |t|
      t.string :shortname
      t.string :name
      t.text :description
      t.text :funding
      t.text :comment

      t.timestamps
    end
  end

  def self.down
    drop_table :projects
  end
end
