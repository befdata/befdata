class AddStatusFieldToSheetcellTable < ActiveRecord::Migration
 def self.up
    # sheetcells
    add_column :sheetcells, :status_id, :integer
  end

  def self.down
    # sheetcell
    remove_column :sheetcells, :status_id
  end
end
