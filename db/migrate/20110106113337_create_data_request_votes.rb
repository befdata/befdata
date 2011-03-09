class CreateDataRequestVotes < ActiveRecord::Migration
  def self.up
    create_table :data_request_votes do |t|
      t.integer :data_request_id
      t.integer :person_id
      t.string :comment
      t.timestamps
    end
  end

  def self.down
    drop_table :data_request_votes
  end
end
