class AddFuzzySearchToPeople < ActiveRecord::Migration
  def self.up
    create_table :person_trigrams, :force => true do |t|
      t.integer :person_id
      t.string  :token, :null => false
    end

    # Trigrams will be created while saving.
    Person.find(:all).each{|p| p.save}
  end

  def self.down
    drop_table :person_trigrams
  end
end
