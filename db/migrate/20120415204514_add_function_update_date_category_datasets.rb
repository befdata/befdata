class AddFunctionUpdateDateCategoryDatasets < ActiveRecord::Migration
  def self.up
    execute <<-SQL

    CREATE OR REPLACE FUNCTION update_date_category_datasets(category_id integer) RETURNS boolean
      LANGUAGE sql AS
        $_$update datasets
           set updated_at = now()
          from sheetcells sc inner join datacolumns dc on sc.datacolumn_id = dc.id
          where category_id = $1 and datasets.id = dc.dataset_id
      returning true$_$;

    SQL
  end

  def self.down
  end
end
