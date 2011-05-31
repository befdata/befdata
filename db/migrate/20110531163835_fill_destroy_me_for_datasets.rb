class FillDestroyMeForDatasets < ActiveRecord::Migration
  def self.up
    Dataset.all.each do |ds|
      ds.update_attributes(:destroy_me => false)
    end
  end
end
