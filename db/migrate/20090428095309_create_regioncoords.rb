class CreateRegioncoords < ActiveRecord::Migration
  def self.up
    create_table :regioncoords do |t|
      t.integer :location_id
      t.float :latitude
      t.float :longitude
      t.integer :rank
      t.boolean :reference
      t.float :xdim
      t.float :xangle
      t.float :ydim
      t.float :yangle
      t.float :area
      t.text :comment

      t.timestamps
    end
  end

  def self.down
    drop_table :regioncoords
  end
end
