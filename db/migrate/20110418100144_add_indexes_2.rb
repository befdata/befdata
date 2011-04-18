class AddIndexes2 < ActiveRecord::Migration
  def self.up
    # datacolumns
    add_index :datacolumns, [:datagroup_id]

    # categoricvalues
    add_index :categoricvalues, [:short]

    # roles_users
    add_index :roles, [:authorizable_type,:authorizable_id]
  end

  def self.down
    # datacolumns
    remove_index :datacolumns, [:datagroup_id]

    # categoricvalues
    remove_index :categoricvalues, [:short]

    # roles
    remove_index :roles, [:authorizable_type,:authorizable_id]
  end
end
