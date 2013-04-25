class AcceptInvalidValues < ActiveRecord::Migration
  def up
    execute <<-SQL
      --
      -- Name: accept_invalid_values(integer, integer); Type: FUNCTION; Schema: public; Owner: -
      --
      CREATE OR REPLACE FUNCTION accept_invalid_values(datacolumn_id integer, datagroup_id integer, user_id integer, "comment" text) RETURNS boolean
          LANGUAGE sql
          AS $_$
          -- 1. add a category for each unique invalid value, as long as one doesn't already exist in the data group
            insert into categories (short, long, description, datagroup_id, status_id, created_at, updated_at, user_id, comment)
            (
              select distinct sheetcells.import_value, sheetcells.import_value, sheetcells.import_value, $2 as datagroup_id, 2 as status_id, now() as created_at, now() as updated_at,
                $3 as user_id, $4 as comment
              from sheetcells
              where sheetcells.datacolumn_id=$1
                and sheetcells.status_id = 5
                and not exists (
                  select 1 from categories where (short = sheetcells.import_value or long = sheetcells.import_value) and datagroup_id = $2
                )
            );
          -- 2. update the sheet cells with the correct category
            update sheetcells
              set category_id= c.id,
                  updated_at = now(),
                  datatype_id = 5, -- whatever the original data type this is now a category data type
                  accepted_value = null,
                  status_id = 4   -- Valid
              from categories c
              where c.datagroup_id = $2
                and sheetcells.datacolumn_id=$1
                and sheetcells.status_id = 5 -- invalid values
                and (sheetcells.import_value = c.short  or sheetcells.import_value = c.long)
          returning true$_$;
    SQL
  end

  def down
  end
end
