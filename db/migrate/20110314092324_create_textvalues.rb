class CreateTextvalues < ActiveRecord::Migration
  def self.up
    create_table :textvalues do |t|
      t.string   "text"
      t.text     "comment"
      t.timestamps
    end
  end

  def self.down
    drop_table :textvalues
  end
end
