class RenameDataRequestsToSingular < ActiveRecord::Migration
  def self.up
    rename_column :filevalues, :data_requests_id, :data_request_id
  end

  def self.down
    rename_column :filevalues, :data_request_id, :data_requests_id
  end
end
