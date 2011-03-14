class CreateDataGroups < ActiveRecord::Migration
  def self.up
    create_table :data_groups do |t|
      t.string   "informationsource"
      t.string   "methodvaluetype"
      t.string   "title"
      t.text     "description"
      t.string   "instrumentation"
      t.float    "timelatency"
      t.string   "timelatencyunit"
      t.text     "comment"
      t.timestamps
    end
  end

  def self.down
    drop_table :data_groups
  end
end
