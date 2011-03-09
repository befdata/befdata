class RenameTableCartDataColumn < ActiveRecord::Migration
  def self.up
    rename_table :cart_data_columns, :cart_contexts
    rename_column :cart_contexts, :measurements_methodstep_id, :context_id
  end

  def self.down
    rename_column :cart_contexts, :context_id, :measurements_methodstep_id
    rename_table :cart_contexts, :cart_data_columns

  end
end
