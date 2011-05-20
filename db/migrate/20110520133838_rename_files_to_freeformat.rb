class RenameFilesToFreeformat < ActiveRecord::Migration
  def self.up
    rename_table :files, :freeformats
  end

  def self.down
    rename_table :freeformats, :files
  end
end
