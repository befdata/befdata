class CreateContextFreepeople < ActiveRecord::Migration
  def self.up
    create_table :context_freepeople do |t|
      t.integer :person_id
      t.integer :context_id
      t.text :comment

      t.timestamps
    end
  end

  def self.down
    drop_table :context_freepeople
  end
end
