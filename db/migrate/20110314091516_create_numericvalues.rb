class CreateNumericvalues < ActiveRecord::Migration
  def self.up
    create_table :numericvalues do |t|
      t.float    "number"
      t.text     "comment"
      t.timestamps
    end
  end

  def self.down
    drop_table :numericvalues
  end
end
