class CreateDatasetsModelsLinkTable < ActiveRecord::Migration
  def self.up
    create_table :datasets_projects do |t|
      t.integer  "dataset_id"
      t.integer  "project_id"
      t.text     "comment"
      t.timestamps
    end
  end

  def self.down
    drop_table :datasets_projects
  end
end
