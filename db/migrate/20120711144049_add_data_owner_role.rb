class AddDataOwnerRole < ActiveRecord::Migration
  def self.up
    Role.create(:name => "data_admin")
  end

  def self.down
  end
end
