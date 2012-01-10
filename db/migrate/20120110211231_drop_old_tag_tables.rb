class DropOldTagTables < ActiveRecord::Migration
  def self.up
    drop_table :old_tags
    drop_table :old_taggings
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
