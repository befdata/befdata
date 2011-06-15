class RenameNewColumnInPaperproposals < ActiveRecord::Migration
  def self.up
    rename_column :paperproposals, :authoring_project, :project_id
  end

  def self.down
    rename_column :paperproposals, :project_id, :authoring_project
  end
end
