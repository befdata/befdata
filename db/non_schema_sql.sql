--
-- Name: accept_text_datacolumn_values(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE OR REPLACE FUNCTION accept_text_datacolumn_values(datacolumn_id integer) RETURNS boolean
    LANGUAGE sql
    AS $_$-- text data types are not linked to categories so we can just update the accepted value
      update sheetcells
      set category_id = null,
          accepted_value=sheetcells.import_value,
          updated_at = now(),
          datatype_id = 1,
          status_id = 4
      where sheetcells.datacolumn_id=$1
      returning true;$_$;


--
-- Name: clear_datacolumn_accepted_values(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE OR REPLACE FUNCTION clear_datacolumn_accepted_values(datacolumn_id integer) RETURNS boolean
    LANGUAGE sql
    AS $_$
      update sheetcells
      set accepted_value=null,
          category_id=null,
          status_id=1
      where datacolumn_id=$1
      returning true$_$;

--
-- Name: isdate(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE OR REPLACE FUNCTION isdate(text text) RETURNS boolean
    LANGUAGE plpgsql
    AS $_$begin
                if $1 is null then
                   return 0;
                else
                   perform $1::date;
                   return 1;
                end if;
                exception when others then
                return 0;
                end$_$;


--
-- Name: isinteger(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE OR REPLACE FUNCTION isinteger(year text) RETURNS boolean
    LANGUAGE sql
    AS $_$select $1 ~ '^[0-9]+$'$_$;


--
-- Name: isnumeric(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE OR REPLACE FUNCTION isnumeric(text text) RETURNS boolean
    LANGUAGE sql
    AS $_$select $1 ~
              '^(?![<>])[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?$'$_$;

--
-- Name: accept_datacolumn_values(integer, integer, integer, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE OR REPLACE FUNCTION accept_datacolumn_values(datatype_id integer, datacolumn_id integer, datagroup_id integer, "comment" text) RETURNS boolean
    LANGUAGE sql
    AS $_$          -- regardless of the data type we search for portal matches first
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
                -- this is a two step process to avoid duplicate categories being created
                -- 1. add a category for each unique sheet category match, as long as one doesn't already exist in the data group
                insert into categories (short, long, description, datagroup_id, created_at, updated_at, comment)
                  (
                    select distinct ic.short, ic.long, ic.description, $3 as datagroup_id, now() as created_at, now() as updated_at, $4 as comment
                    from import_categories ic inner join sheetcells s on (s.import_value=ic.short or s.import_value=ic.long)
                    and s.datacolumn_id=$2 and ic.datacolumn_id=$2
                    and s.category_id is null and s.status_id = 1
                        and not exists (select 1 from categories where (short = s.import_value or long = s.import_value) and datagroup_id = $3)
                  );

                -- 2. update the sheet cells with the correct category
                update sheetcells
                set category_id= c.id,
                  updated_at = now(),
                  datatype_id = 5, -- whatever the original data type this is now a category data type
                  accepted_value = null,
                  status_id = 2 -- it is an sheet match category
                from categories c
                where (sheetcells.import_value=c.short or sheetcells.import_value=c.long)
                and sheetcells.datacolumn_id=$2 and c.datagroup_id = $3 and sheetcells.category_id is null and sheetcells.accepted_value is null;

                -- valid number, date & year
                update sheetcells
                  set category_id = null,
                  accepted_value = sheetcells.import_value,
                  updated_at = now(),
                  datatype_id = $1,
                  status_id = 4
                where sheetcells.datacolumn_id=$2
                and (($1 = 7 and isnumeric(sheetcells.import_value) = true)
                  or ($1 = 2 and isinteger(sheetcells.import_value) = true)
                  or (($1 = 3 or $1 = 4) and isdate(sheetcells.import_value) = true)
                  )
                and sheetcells.category_id is null;

                 -- regardless of the data type any sheetcells left over are flagged as invalid
                update sheetcells
                set updated_at = now(),
		            datatype_id = $1,
                    status_id = 5 -- invalid
                where sheetcells.datacolumn_id=$2 and sheetcells.category_id is null and sheetcells.accepted_value is null
      returning true$_$;

--
-- Name: accept_invalid_values(integer, integer, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE OR REPLACE FUNCTION accept_invalid_values(datacolumn_id integer, datagroup_id integer, "comment" text) RETURNS boolean
    LANGUAGE sql
    AS $_$
    -- 1. add a category for each unique invalid value, as long as one doesn't already exist in the data group
      insert into categories (short, long, description, datagroup_id, created_at, updated_at, comment)
      (
        select distinct s.import_value, s.import_value, s.import_value, $2 as datagroup_id, now() as created_at, now() as updated_at,
          $3 as comment
        from sheetcells s
        where s.datacolumn_id=$1
          and s.status_id = 5
          and not exists (
            select 1 from categories where (short = s.import_value or long = s.import_value) and datagroup_id = $2
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


--
-- Name: update_date_category_datasets(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE OR REPLACE FUNCTION update_date_category_datasets(category_id integer) RETURNS boolean
    LANGUAGE sql AS
      $_$update exported_files
         set invalidated_at = now() AT TIME ZONE 'UTC'
        from sheetcells sc inner join datacolumns dc on sc.datacolumn_id = dc.id
        where category_id = $1 and exported_files.dataset_id = dc.dataset_id
    returning true$_$;
--
--- Name: expire_exported_files_upon_datagroup_change; Type: FUNCTION; Schema: public; Owner: -
--

CREATE OR REPLACE FUNCTION expire_exported_files_upon_datagroup_change(datagroup_id int) RETURNS void
AS $$
  update exported_files
    set invalidated_at = now() AT TIME ZONE 'UTC'
  from datacolumns
  where exported_files.dataset_id = datacolumns.dataset_id
  and datacolumns.datagroup_id = $1
  and exported_files.type = 'ExportedExcel'; --- only affect exported Excel files
$$ language sql;

--
--- Define a view
--
CREATE OR REPLACE view dataset_tags AS
  (
    select taggable_id as dataset_id, tag_id
    from taggings
    where taggable_type = 'Dataset'
  union
    select distinct d.dataset_id, g.tag_id
    from taggings g join datacolumns d
    on g.taggable_id = d.id
    where g.taggable_type = 'Datacolumn'
  );
