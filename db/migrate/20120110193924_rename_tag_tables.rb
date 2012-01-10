class RenameTagTables < ActiveRecord::Migration
  def self.up
    remove_index "taggings", ["tag_id"]
    remove_index "taggings", ["taggable_id", "taggable_type"]
    rename_table :tags, :old_tags
    rename_table :taggings, :old_taggings
  end

  def self.down
    rename_table :old_tags, :tags
    rename_table :old_taggings, :taggings
  end
end
