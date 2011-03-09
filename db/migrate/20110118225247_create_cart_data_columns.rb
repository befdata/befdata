class CreateCartDataColumns < ActiveRecord::Migration
  def self.up
    create_table :cart_data_columns do |t|
      t.integer :cart_id
      t.integer :measurements_methodstep_id
      t.timestamps
    end
  end

  def self.down
    drop_table :cart_data_columns
  end
end
