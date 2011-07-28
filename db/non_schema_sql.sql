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
    AS $_$update sheetcells
                      set accepted_value=null,
                      category_id=null,
                      status_id=1
                      where datacolumn_id=$1

                      returning true$_$;


--
-- Name: insert_category(text, text, integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE OR REPLACE FUNCTION insert_category(short text, long text, datagroup_id integer, status_id integer) RETURNS integer
    LANGUAGE sql
    AS $_$insert into categories (short, long, datagroup_id, status_id, created_at, updated_at)
                    (select $1 as short, $2 as long, $3 as datagroup_id, $4 as status_id, now() as created_at, now() as updated_at where
                not exists (select 1 from categories where (short=$1 or long=$2) and datagroup_id = $3));

                select id from categories where (short=$1 or long=$2) and datagroup_id = $3;$_$;


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
              '^[0-9]+.?[0-9]*$'$_$;


--
-- Name: isyear(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE OR REPLACE FUNCTION isyear(year text) RETURNS boolean
    LANGUAGE sql
    AS $$select 1=1$$;


--
-- Name: accept_datacolumn_values(integer, integer, integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE OR REPLACE FUNCTION accept_datacolumn_values(datatype_id integer, datacolumn_id integer, datagroup_id integer, system_datagroup_id integer) RETURNS boolean
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
      returning true$_$;