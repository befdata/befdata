class AddCounterToContexts < ActiveRecord::Migration
  def self.up
    add_column :contexts, :downloads, :integer, :default => '0', :null => 'false'
  end

  def self.down
    remove_column :contexts, :downloads
  end
end
