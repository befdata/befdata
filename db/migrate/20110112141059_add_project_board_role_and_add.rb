class AddProjectBoardRoleAndAdd < ActiveRecord::Migration
  def self.up
    role = Role.new(:name => "project board")
    role.save
    karin = Person.find_by_firstname("Karin")
    daniel = Person.find_by_lastname("Seifarth")
    project = daniel.person_roles.first.project
    daniel.person_roles << PersonRole.new(:project => project,
                                         :person => daniel,
                                         :role => role)
    karin.person_roles << PersonRole.new(:project => project,
                                         :person => karin,
                                         :role => role)
  end

  def self.down
  end
end
