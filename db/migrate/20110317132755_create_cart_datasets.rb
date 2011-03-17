class CreateCartsDatasets < ActiveRecord::Migration
  def self.up
    create_table :carts_datasets do |t|
      t.integer  "id",         :null => false
      t.integer  "cart_id"
      t.integer  "dataset_id"
      t.timestamps
    end
  end

  def self.down
    drop_table :carts_datasets
  end
end
