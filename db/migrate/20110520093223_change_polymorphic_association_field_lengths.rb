class ChangePolymorphicAssociationFieldLengths < ActiveRecord::Migration
  def self.up
    change_column :sheetcells, :value_type, :string, :limit => 25
    change_column :taggings, :taggable_type, :string, :limit => 25
    change_column :roles, :authorizable_type, :string, :limit => 25
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
