class AddLongshortColumnToMeasmeth < ActiveRecord::Migration
  def self.up
    add_column :measurements_methodsteps, :category_longshort, :string
  end 

  def self.down
    remove_column :measurements_methodsteps, :category_longshort
  end
end
