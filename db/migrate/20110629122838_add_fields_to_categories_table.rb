class AddFieldsToCategoriesTable < ActiveRecord::Migration
  def self.up
    # categories
    add_column :categories, :datagroup_id, :integer
    add_column :categories, :user_id, :integer
    add_column :categories, :status_id, :integer
    #datagroups
    add_column :datagroups, :system, :boolean
  end

  def self.down
    # categories
    remove_column :categories, :datagroup_id
    remove_column :categories, :user_id
    remove_column :categories, :status_id
    #datagroups
    remove_column :datagroups, :system
  end
end
