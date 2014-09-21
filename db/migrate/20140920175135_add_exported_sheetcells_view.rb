class AddExportedSheetcellsView < ActiveRecord::Migration
  def up
    execute <<-'SQL'
      create or replace view exported_sheetcells as
      select
          sheetcells.id,
          dataset_id,
          datacolumn_id,
          columnnr,
          row_number,
          (category_id is not null) as is_category,
          case
            when category_id is not null
              then (select short from categories where id = category_id)
            when accepted_value is not null
              then accepted_value
            else import_value
          end as export_value
       from sheetcells left join datacolumns on datacolumns.id = datacolumn_id;
    SQL
  end

  def down
    execute <<-SQL
      drop view if exists exported_sheetcells;
    SQL
  end
end
