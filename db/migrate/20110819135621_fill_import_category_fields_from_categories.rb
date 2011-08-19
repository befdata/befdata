class FillImportCategoryFieldsFromCategories < ActiveRecord::Migration
  def self.up
    import_categories = ImportCategory.all.select
    import_categories.each { |ic|
      ic.update_attributes(:short => ic.category.short,
                          :long => ic.category.long,
                          :description => ic.category.description)

    }
  end

  def self.down
    #raise ActiveRecord::IrreversibleMigration
  end
end