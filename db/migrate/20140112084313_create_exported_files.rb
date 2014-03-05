class CreateExportedFiles < ActiveRecord::Migration
  def change
    create_table :exported_files do |t|
      t.integer  :dataset_id
      t.string   :status, :default => 'new', :null => false
      t.datetime :generated_at
      t.datetime :invalidated_at, :default => Time.utc(1970, 1, 1)
      t.string   :file_file_name
      t.integer  :file_file_size
      t.string   :type
    end

    add_index :exported_files, :dataset_id
  end
end
