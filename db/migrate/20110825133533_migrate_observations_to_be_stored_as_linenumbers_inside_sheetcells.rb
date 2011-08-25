class MigrateObservationsToBeStoredAsLinenumbersInsideSheetcells < ActiveRecord::Migration
  def self.up
    add_column(:sheetcells, :row_number, :integer)

    puts "Migration #{Observation.count} observations"
    Observation.all.each do |observation| #yes i know this will take a loooong time ;)
      print '.'
      observation.sheetcells.each do |cell|
        cell.row_number = observation.rownr
        cell.save
      end
    end
  end

  def self.down
    remove_column(:sheetcells, :row_number)
  end
end
