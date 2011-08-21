class RemoveUnusedFieldsFromImportCategories < ActiveRecord::Migration
  def self.up
    remove_column :import_categories, :raw_data_value
    remove_column :import_categories, :approved
    remove_column :import_categories, :category_id
  end

  def self.down
  end
end
