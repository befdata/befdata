class CreateContextFreeprojects < ActiveRecord::Migration
  def self.up
    create_table :context_freeprojects do |t|
      t.integer :project_id
      t.integer :context_id
      t.text :comment

      t.timestamps
    end
  end

  def self.down
    drop_table :context_freeprojects
  end
end
