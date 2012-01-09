class AddInformationsourceAndInstrumentationToDatacolumnsTable < ActiveRecord::Migration
  def self.up
    add_column :datacolumns, :informationsource, :string
    add_column :datacolumns, :instrumentation, :string
  end

  def self.down
    remove_column :datacolumns, :informationsource
    remove_column :datacolumns, :instrumentation
  end
end
