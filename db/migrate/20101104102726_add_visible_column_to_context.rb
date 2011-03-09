class AddVisibleColumnToContext < ActiveRecord::Migration
  def self.up
    add_column :contexts, :visible_for_public, :boolean, :default => true
  end

  def self.down
    remove_column :contexts, :visible_for_public
  end
end
