class RemoveTimeZoneFromDatetimeValues < ActiveRecord::Migration
  def up
    execute <<-'SQL'
      update sheetcells
      set import_value = to_char(import_value::timestamp, 'YYYY-MM-DD HH24:MI:SS')
      where import_value ~ '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\+\d{2}:\d{2}$';

      update sheetcells
      set accepted_value = to_char(accepted_value::timestamp, 'YYYY-MM-DD HH24:MI:SS')
      where accepted_value ~ '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\+\d{2}:\d{2}$';
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
