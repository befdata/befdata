require 'active_record/fixtures'

class AddDatatypeIdFieldToSheetcell < ActiveRecord::Migration
  def self.up
    add_column :sheetcells, :datatype_id, :integer

    directory = File.join(File.dirname(File.dirname(File.dirname(__FILE__))), "test/fixtures")
    Fixtures.create_fixtures(directory, "datatypes")
  end

  def self.down
    remove_column :sheetcells, :datatype_id

    Datatype.delete_all
  end
end
