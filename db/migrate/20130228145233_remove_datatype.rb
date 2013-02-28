class RemoveDatatype < ActiveRecord::Migration
  def up
    drop_table :datatypes if table_exists?(:datatypes)
  end

  def down
    create_table "datatypes" do |t|
      t.string "name"
      t.string "format"
    end
  end
end
