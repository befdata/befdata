class RenameAndAddSomeDataRequestFeatures < ActiveRecord::Migration
  def self.up
    add_column :data_request_votes, :vote, :string, :default => "none"
    rename_column :data_requests, :abstract, :rationale
    add_column :author_data_requests, :kind, :string
  end

  def self.down
    rename_column :data_requests, :rationale, :abstract
    remove_column :data_request_votes, :vote
    remove_column :author_data_requests, :kind
  end
end
