class UpdateIsnumericSqlFunction < ActiveRecord::Migration
  def self.up
    execute <<-SQL
      CREATE OR REPLACE FUNCTION isnumeric(text text) RETURNS boolean
        LANGUAGE sql
        AS $_$select $1 ~
                  '^(?![<>])[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?$'$_$;
    SQL
  end

  def self.down
  end
end
