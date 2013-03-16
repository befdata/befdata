class DatasetHasManyDatafiles < ActiveRecord::Migration
  def up
    add_column :datafiles, :dataset_id, :integer
    add_index :datafiles, :dataset_id
    execute <<-SQL
      update datafiles
      set dataset_id = datasets.id
      from datasets
      where datasets.upload_spreadsheet_id = datafiles.id
    SQL
    remove_index :datasets, :upload_spreadsheet_id
    remove_column :datasets, :upload_spreadsheet_id
  end

  def down
    add_column :datasets, :upload_spreadsheet_id, :integer
    add_index "datasets", ["upload_spreadsheet_id"], :name => "index_datasets_on_upload_spreadsheet_id"
    execute <<-SQL
      update datasets
      set upload_spreadsheet_id = (
        select max(datafiles.id)
        from datafiles
        where datafiles.dataset_id = datasets.id
      )
    SQL
    remove_index :datafiles, :dataset_id
    remove_column :datafiles, :dataset_id
  end
end
