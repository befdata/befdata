class AddExternalDataTextField < ActiveRecord::Migration
  def self.up
    add_column :data_requests, :external_data, :string
  end

  def self.down
    remove_column :data_request, :external_data
  end
end
