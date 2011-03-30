class CreateCategoricvalues < ActiveRecord::Migration
  def self.up
    create_table :categoricvalues do |t|
      t.string   "short"
      t.string   "long"
      t.text     "description"
      t.text     "comment"
      t.timestamps
    end
  end

  def self.down
    drop_table :categoricvalues
  end
end
