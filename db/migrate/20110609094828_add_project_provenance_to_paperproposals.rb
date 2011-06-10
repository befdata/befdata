class AddProjectProvenanceToPaperproposals < ActiveRecord::Migration
  def self.up
    add_column :paperproposals, :authoring_project, :integer
  end

  def self.down
    remove_column :paperproposals, :authoring_project
  end
end
