class CreateTags < ActiveRecord::Migration
  def self.up
    create_table :tags do |t|
      t.string "name", :default => ""
      t.string "kind", :default => ""
    end
  end

  def self.down
    drop_table :tags
  end
end
