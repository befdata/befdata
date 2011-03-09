class CreateImportCategories < ActiveRecord::Migration
  def self.up
    create_table :import_categories do |t|
      t.integer :measurements_methodstep_id
      t.string :raw_data_value
      t.integer :categoricvalue_id
      t.boolean :approved

      t.timestamps
    end
  end

  def self.down
    drop_table :import_categories
  end
end
