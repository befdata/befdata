class CreateAuthorDataRequests < ActiveRecord::Migration
  def self.up
    create_table :author_data_requests do |t|
      t.integer :data_request_id
      t.integer :person_id
      t.timestamps
    end
  end

  def self.down
    drop_table :author_data_requests
  end
end
