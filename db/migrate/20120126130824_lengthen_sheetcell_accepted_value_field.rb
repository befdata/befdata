class LengthenSheetcellAcceptedValueField < ActiveRecord::Migration
  def self.up
    change_column(:sheetcells, :accepted_value, :string, :limit => 255)
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
