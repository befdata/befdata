class AddDestroyMeToDatasets < ActiveRecord::Migration
  def self.up
    add_column :datasets, :destroy_me, :boolean, :default => false
    add_column :datasets, :destroy_me_date, :date
  end

  def self.down
    remove_column :datasets, :destroy_me
    remove_column :datasets, :destroy_me_date
  end
end
