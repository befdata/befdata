class ReassignProjectsToPaperproposals < ActiveRecord::Migration
  def self.up
  ## looping through projects to get associated paperproposals and fill the
  ## paperproposals projects link table
    projects = Project.all
    projects.each do |project|
      project_paperproposal_roles = project.role_objects.select { |ro| ro.authorizable_type == "Paperproposal" }
      project_paperproposal_roles.each do |role|
        paperproposal = Paperproposal.find(role.authorizable_id)
        paperproposal.update_attributes(:authored_by_project => project)
      end
    end

  end


end
