class UpdateFunctionsForAddingDataValues < ActiveRecord::Migration
  def self.up
    execute <<-SQL
      CREATE OR REPLACE FUNCTION accept_text_datacolumn_values(datacolumn_id integer)
        RETURNS boolean AS
      $BODY$-- text data types are not linked to categories so we can just update the accepted value
                update sheetcells
                  set category_id = null,
                  accepted_value=sheetcells.import_value,
                  updated_at = now(),
                  datatype_id = 1,
                  status_id = 4
                where sheetcells.datacolumn_id=$1
          returning true;$BODY$
        LANGUAGE sql VOLATILE
        COST 100;
      ALTER FUNCTION accept_text_datacolumn_values(integer) OWNER TO postgres;
    SQL

    execute <<-SQL
      CREATE OR REPLACE FUNCTION insert_category(short text, "long" text, datagroup_id integer, status_id integer)
        RETURNS integer AS
      $BODY$insert into categories (short, long, datagroup_id, status_id, created_at, updated_at)
                    (select $1 as short, $2 as long, $3 as datagroup_id, $4 as status_id, now() as created_at, now() as updated_at where
                not exists (select 1 from categories where (short=$1 or long=$2) and datagroup_id = $3));

                select id from categories where (short=$1 or long=$2) and datagroup_id = $3;$BODY$
        LANGUAGE sql VOLATILE
        COST 100;
      ALTER FUNCTION insert_category(text, text, integer, integer) OWNER TO postgres;
    SQL

    execute <<-SQL
     CREATE OR REPLACE FUNCTION isdate("text" text)
        RETURNS boolean AS
      $BODY$begin
                if $1 is null then
                   return 0;
                else
                   perform $1::date;
                   return 1;
                end if;
                exception when others then
                return 0;
                end$BODY$
        LANGUAGE plpgsql VOLATILE
        COST 100;
      ALTER FUNCTION isdate(text) OWNER TO postgres;
    SQL

    execute <<-SQL
       CREATE OR REPLACE FUNCTION isinteger("year" text)
        RETURNS boolean AS
      $BODY$select $1 ~ '^[0-9]+$'$BODY$
        LANGUAGE sql VOLATILE
        COST 100;
      ALTER FUNCTION isinteger(text) OWNER TO postgres;
    SQL


    execute <<-SQL
       CREATE OR REPLACE FUNCTION isnumeric("text" text)
        RETURNS boolean AS
      $BODY$select $1 ~
              '^[0-9]+\.?[0-9]*$'$BODY$
        LANGUAGE sql VOLATILE
        COST 100;
      ALTER FUNCTION isnumeric(text) OWNER TO postgres;
    SQL

    execute <<-SQL
      CREATE OR REPLACE FUNCTION accept_datacolumn_values(datatype_id integer, datacolumn_id integer, datagroup_id integer, system_datagroup_id integer)
        RETURNS boolean AS
      $BODY$          -- regardless of the data type we search for portal matches first
                update sheetcells
                set category_id= c.id,
                  updated_at = now(),
                  datatype_id = 5, -- whatever the original data type this is now a category data type
                  accepted_value = null,
                  status_id = 3
                from categories c
                where (sheetcells.import_value=c.short or sheetcells.import_value=c.long)
                and sheetcells.datacolumn_id=$2 and c.datagroup_id = $3;

                -- regardless of the data type we search for sheet matches next
                update sheetcells
                set category_id = insert_category(sheetcells.import_value, sheetcells.import_value, $3, 1),
                  updated_at = now(),
                  datatype_id = 5, -- whatever the original data type this is now a category data type
                  accepted_value=null,
                  status_id = 2
                from categories c inner join import_categories cv on c.id = cv.category_id
                where (sheetcells.import_value=c.short or sheetcells.import_value=c.long)
                and sheetcells.datacolumn_id=$2 and cv.datacolumn_id=$2
                and sheetcells.category_id is null and c.datagroup_id=$4;

                -- valid number, date & year
                update sheetcells
                  set category_id = null,
                  accepted_value = sheetcells.import_value,
                  updated_at = now(),
                  datatype_id = $1,
                  status_id = 4
                where sheetcells.datacolumn_id=$2
                and ((datatype_id = 7 and isnumeric(sheetcells.import_value) = true)
                  or (datatype_id = 2 and isinteger(sheetcells.import_value) = true)
                  or ((datatype_id = 3 or datatype_id = 4) and isdate(sheetcells.import_value) = true)
                  )
                and sheetcells.category_id is null;

                -- regardless of the data type any sheetcells left over are invalid and categories created for them
                update sheetcells
                set category_id = insert_category(sheetcells.import_value, sheetcells.import_value, $3, 3),
                  accepted_value = null,
                  updated_at = now(),
                  datatype_id = 5, -- whatever the original data type this is now a category data type
                  status_id = 5
                where sheetcells.datacolumn_id=$2 and sheetcells.category_id is null and sheetcells.accepted_value is null
      returning true$BODY$
        LANGUAGE sql VOLATILE
        COST 100;
      ALTER FUNCTION accept_datacolumn_values(integer, integer, integer, integer) OWNER TO postgres;
    SQL

  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
