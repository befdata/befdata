class RenameDataRequestDataColumn < ActiveRecord::Migration
  def self.up
    rename_column :data_group_data_requests, :measurements_methodstep_id, :context_id
    rename_table :data_group_data_requests, :data_request_contexts
  end

  def self.down

    rename_table :data_request_contexts, :data_group_data_requests
    rename_column :data_group_data_requests, :context_id, :measurements_methodstep_id
  end
end
