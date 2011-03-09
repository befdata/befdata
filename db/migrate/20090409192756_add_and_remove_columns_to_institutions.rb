class AddAndRemoveColumnsToInstitutions < ActiveRecord::Migration
  def self.up
    remove_column :institutions, :address
    add_column :institutions, :street, :string
    add_column :institutions, :city, :string
    add_column :institutions, :country, :string

  end

  def self.down
    add_column :institutions, :address, :string
    remove_column :institutions, :street, :string
    remove_column :institutions, :city, :string
    remove_column :institutions, :country, :string
  end
end
