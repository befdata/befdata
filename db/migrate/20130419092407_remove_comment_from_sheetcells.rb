class RemoveCommentFromSheetcells < ActiveRecord::Migration
  def up
    remove_column :sheetcells, :comment
  end

  def down
    add_column :sheetcells, :comment
  end
end
