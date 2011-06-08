class RenameCategoricvalueIdToCategoryIdInImportCv < ActiveRecord::Migration
  def self.up
    rename_column :import_categoricvalues, :categoricvalue_id, :category_id
  end

  def self.down
    rename_column :import_categoricvalues, :category_id, :categoricvalue_id
  end
end
