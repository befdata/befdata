class CreateTaggings < ActiveRecord::Migration
  def self.up
    create_table :taggings do |t|
      t.integer "tag_id"
      t.string  "taggable_type", :default => ""
      t.integer "taggable_id"
    end
  end

  def self.down
    drop_table :taggings
  end
end
