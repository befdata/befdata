class AddColumnsToDataRequestModel < ActiveRecord::Migration
  def self.up
    add_column :data_requests, :corresponding_id, :integer
    add_column :data_requests, :envisaged_date, :date
    add_column :data_requests, :state, :string
    add_column :data_requests, :expiry_date, :date
  end

  def self.down
    remove_column :data_requests, :corresponding_id
    remove_column :data_requests, :envisaged_date
    remove_column :data_requests, :state
    remove_column :data_requests, :expiry_date
  end
end
