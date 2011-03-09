class AddColumnToDataRequest < ActiveRecord::Migration
  def self.up
    add_column :data_requests, :board_state, :string, :default => "prep"
  end

  def self.down
    remove_column :data_requests, :board_state
  end
end
