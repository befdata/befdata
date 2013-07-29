class AddIndexToCategoriesLong < ActiveRecord::Migration
  def change
    add_index :categories, :long
    add_index :import_categories, :short
    add_index :import_categories, :long
  end
end
