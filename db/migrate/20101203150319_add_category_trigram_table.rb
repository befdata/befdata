class AddCategoryTrigramTable < ActiveRecord::Migration
  def self.up
    create_table "categoricvalue_trigrams", :force => true do |t|
      t.integer "categoricvalue_id"
      t.string  "token",   :null => false
    end
  end

  def self.down
    drop_table :categoricvalue_trigrams
  end
end
