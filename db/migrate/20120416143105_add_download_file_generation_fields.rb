class AddDownloadFileGenerationFields < ActiveRecord::Migration
  def self.up
    add_column :datasets, :download_generated_at, :datetime
    add_column :datasets, :download_generation_status, :string
  end

  def self.down
    remove_column :datasets, :download_generated_at
    remove_column :datasets, :download_generation_status
  end
end
