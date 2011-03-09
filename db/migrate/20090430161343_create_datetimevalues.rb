class CreateDatetimevalues < ActiveRecord::Migration
  def self.up
    create_table :datetimevalues do |t|
      t.datetime :date
      t.integer :year
      t.integer :month
      t.integer :day
      t.text :comment

      t.timestamps
    end
  end

  def self.down
    drop_table :datetimevalues
  end
end
