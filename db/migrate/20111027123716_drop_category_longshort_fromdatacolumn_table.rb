class DropCategoryLongshortFromdatacolumnTable < ActiveRecord::Migration
  def self.up
    remove_column :datacolumns, :category_longshort
  end

  def self.down
  end
end
