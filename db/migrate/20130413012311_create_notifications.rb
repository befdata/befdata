class CreateNotifications < ActiveRecord::Migration
  def change
    create_table :notifications do |t|
      t.integer :user_id
      t.text :subject
      t.text :message
      t.boolean :read, :default => false

      t.timestamps
    end
  end
end
