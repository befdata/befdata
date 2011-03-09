class AddUploadWorkbookToContext < ActiveRecord::Migration
  def self.up
    add_column :contexts, :upload_spreadsheet_id, :integer
  end
  def self.down
    remove_column :contexts, :upload_spreadsheet_id
  end

end
