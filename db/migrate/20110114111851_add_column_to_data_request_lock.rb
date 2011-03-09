class AddColumnToDataRequestLock < ActiveRecord::Migration
  def self.up
    add_column :data_requests, :lock, :boolean, :default => false
  end

  def self.down
    remove_column :data_requests, :lock
  end
end
