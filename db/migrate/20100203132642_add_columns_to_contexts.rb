class AddColumnsToContexts < ActiveRecord::Migration
  def self.up
    add_column :contexts, :datemin, :datetime
    add_column :contexts, :datemax, :datetime
    add_column :contexts, :published, :text
  end

  def self.down
    remove_column :contexts, :datemin
    remove_column :contexts, :datemax
    remove_column :contexts, :published
  end
end
