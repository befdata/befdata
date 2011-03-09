class CreateInstitutions < ActiveRecord::Migration
  def self.up
    create_table :institutions do |t|
      t.string :name
      t.text :affiliation
      t.string :address
      t.string :url
      t.string :email
      t.string :phone
      t.string :fax
      t.text :comment

      t.timestamps
    end
  end

  def self.down
    drop_table :institutions
  end
end
