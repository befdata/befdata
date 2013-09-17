class RemoveUserIdAndStatusIdFromCategories < ActiveRecord::Migration
  def up
    remove_index :categories, :status_id
    remove_columns :categories, :user_id, :status_id
  end

  def down
    change_table :categories, :bulk => true do |t|
      t.integer :user_id
      t.integer :status_id
    end
    add_index :categories, :status_id
  end
end
