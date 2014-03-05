class NewPgFunctionToExpireExportedFiels < ActiveRecord::Migration
  def up
    execute <<-SQL
      CREATE OR REPLACE FUNCTION expire_exported_files_upon_datagroup_change(datagroup_id int) RETURNS void
      AS $$
        update exported_files
          set invalidated_at = now() AT TIME ZONE 'UTC'
        from datacolumns
        where exported_files.dataset_id = datacolumns.dataset_id
        and datacolumns.datagroup_id = $1
        and exported_files.type = 'ExportedExcel'; --- only affect exported Excel files
      $$ language sql;

      CREATE OR REPLACE FUNCTION update_date_category_datasets(category_id integer) RETURNS boolean
      AS $_$
        update exported_files
         set invalidated_at = now() AT TIME ZONE 'UTC'
        from sheetcells sc inner join datacolumns dc on sc.datacolumn_id = dc.id
        where category_id = $1 and exported_files.dataset_id = dc.dataset_id
        returning true;
      $_$ LANGUAGE sql;
    SQL
  end

  def down
    execute <<-SQL
      DROP FUNCTION IF EXISTS expire_exported_files_upon_datagroup_change(int);

      CREATE OR REPLACE FUNCTION update_date_category_datasets(category_id integer) RETURNS boolean
      LANGUAGE sql AS
        $_$update datasets
           set updated_at = now() AT TIME ZONE 'UTC'
          from sheetcells sc inner join datacolumns dc on sc.datacolumn_id = dc.id
          where category_id = $1 and datasets.id = dc.dataset_id
      returning true$_$;
    SQL
  end
end
