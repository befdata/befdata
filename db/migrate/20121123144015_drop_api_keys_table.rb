class DropApiKeysTable < ActiveRecord::Migration
  def self.up
    drop_table :api_keys
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
