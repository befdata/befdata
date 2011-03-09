class AddProjectShortnameToPersonRoles < ActiveRecord::Migration
  def self.up
    add_column :person_roles, :project_shortname, :string
  end

  def self.down
    remove_column :person_roles, :project_shortname
  end
end
