class CreateTableAcl9JoinTable < ActiveRecord::Migration
  def self.up
    create_table "people_roles", :id => false, :force => true do |t|
      t.references  :person
      t.references  :role
      t.timestamps
    end
  end

  def self.down
    drop_table "people_roles"
  end
end
