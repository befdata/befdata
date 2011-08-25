class RemoveDestroyMeMarkers < ActiveRecord::Migration
  def self.up
    Dataset.find_all_by_destroy_me(true).each do |dataset|
      p "Destroying dataset #{dataset.title}"
      dataset.destroy
    end
    remove_column :datasets, :destroy_me
    remove_column :datasets, :destroy_me_date
  end

  def self.down
    add_column :datasets, :destroy_me, :boolean, :default => fals
    add_column :datasets, :destroy_me_date, :date
  end
end
