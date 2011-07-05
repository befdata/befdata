class AddDescriptionToFreeformat < ActiveRecord::Migration
  def self.up
    add_column :freeformats, :description, :text
  end

  def self.down
    remove_column :freeformats, :description
  end
end
