class AddSeniorAuthorToDataRequest < ActiveRecord::Migration
  def self.up
    add_column :data_requests, :senior_author_id, :integer
  end

  def self.down
    remove_column :data_requests, :senior_author_id
  end
end
