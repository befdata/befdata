class AddExtentColumnToContext < ActiveRecord::Migration
  def self.up
    add_column :contexts, :studyextent, :text
  end

  def self.down
    remove_column :contexts, :studyextent
  end
end
