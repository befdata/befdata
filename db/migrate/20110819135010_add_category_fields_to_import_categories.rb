class AddCategoryFieldsToImportCategories < ActiveRecord::Migration
  def self.up
    add_column :import_categories, :short, :string, :limit => 255
    add_column :import_categories, :long, :string, :limit => 255
    add_column :import_categories, :description, :text
  end

  def self.down
    remove_column :import_categories, :short
    remove_column :import_categories, :long
    remove_column :import_categories, :description
  end
end
