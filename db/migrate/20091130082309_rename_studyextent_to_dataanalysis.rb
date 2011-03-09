class RenameStudyextentToDataanalysis < ActiveRecord::Migration
  def self.up
    rename_column :contexts, :studyextent, :dataanalysis
  end

  def self.down
    rename_column :contexts, :dataanalysis, :studyextent
  end
end
