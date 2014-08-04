class AddAlumniToUsers < ActiveRecord::Migration
  def change
    add_column :users, :alumni, :boolean, default: false
  end
end
