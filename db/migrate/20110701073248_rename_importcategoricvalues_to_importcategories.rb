class RenameImportcategoricvaluesToImportcategories < ActiveRecord::Migration
  def self.up
    rename_table :import_categoricvalues, :import_categories
  end

  def self.down
     rename_table :import_categories, :import_categoricvalues
  end
end
