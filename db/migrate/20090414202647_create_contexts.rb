class CreateContexts < ActiveRecord::Migration
  def self.up
    create_table :contexts do |t|
      t.string :title
      t.text :abstract
      t.text :usagerights
      t.text :spatialextent
      t.text :temporalextent
      t.text :taxonomicextent
      t.text :design
      t.text :circumstances
      t.datetime :submission_at
      t.string :filename
      t.text :comment

      t.timestamps
    end
  end

  def self.down
    drop_table :contexts
  end
end
