class CreateDatasetEdits < ActiveRecord::Migration
  def change
    create_table :dataset_edits do |t|
      t.references :dataset
      t.text :description
      t.boolean :submitted, :default => false

      t.timestamps
    end
    add_index :dataset_edits, :dataset_id
  end
end
