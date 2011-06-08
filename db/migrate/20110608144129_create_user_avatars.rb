class CreateUserAvatars < ActiveRecord::Migration
  def self.up
    create_table :user_avatars do |t|
      t.string :user_avatar_file_name
      t.string :user_avatar_content_type
      t.integer :user_avatar_file_size

      t.timestamps
    end
    add_column :users, :user_avatar_id, :integer
  end

  def self.down
    drop_table :user_avatars
    remove_column :users, :user_avatar_id
  end
end
