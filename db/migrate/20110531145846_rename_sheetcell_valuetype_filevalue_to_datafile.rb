class RenameSheetcellValuetypeFilevalueToDatafile < ActiveRecord::Migration
  def self.up
    filevalue_sheetcells = Sheetcell.all.select{|cl| cl.value_type == "Filevalue"}
    filevalue_sheetcells.each do |cl|
      cl.update_attributes(:value_type => "Datafile")
    end # sheetcell renaming
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
