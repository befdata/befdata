class MoveGeneratedDownloadToExportedFiles < ActiveRecord::Migration
  def up
    execute <<-SQL
      insert into exported_files(dataset_id, type, status, generated_at, invalidated_at, file_file_name, file_file_size)
      select id, 'ExportedExcel', download_generation_status, download_generated_at, updated_at, generated_spreadsheet_file_name, generated_spreadsheet_file_size
      from datasets;
    SQL
    remove_columns :datasets, [
                      :download_generated_at,
                      :download_generation_status,
                      :generated_spreadsheet_file_name,
                      :generated_spreadsheet_content_type,
                      :generated_spreadsheet_file_size,
                      :generated_spreadsheet_updated_at
                    ]
  end

  def down
  end
end
