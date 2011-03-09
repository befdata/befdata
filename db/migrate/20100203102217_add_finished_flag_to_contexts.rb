class AddFinishedFlagToContexts < ActiveRecord::Migration
  def self.up
    add_column :contexts, :finished, :boolean
  end

  def self.down
    remove_column :contexts, :finished
  end
end
