class RemoveObsoleteFields < ActiveRecord::Migration
  def up
    remove_column :datasets, :student_file
    remove_index :datasets, :filename
  end

  def down
    add_column :datasets, :student_file, :boolean, :default => false
    add_index :datasets, :filename
  end
end
