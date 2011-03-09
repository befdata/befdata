class CreateDataGroupDataRequests < ActiveRecord::Migration
  def self.up
    create_table :data_group_data_requests do |t|
      t.string :aspect
      t.integer :data_request_id
      t.integer :measurements_methodstep_id
      t.timestamps
    end
  end

  def self.down
    drop_table :data_group_data_requests
  end
end
