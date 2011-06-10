class AssortProjectsToDatasets < ActiveRecord::Migration
  ## looping through projects to get associated datasets and fill the
  ## datasets projects link table
  def self.up
    projects = Project.all
    projects.each do |project|
      project_dataset_roles = project.role_objects.select { |ro| ro.authorizable_type == "Dataset" }
      project_dataset_roles.each do |role|
        dataset = Dataset.find(role.authorizable_id)
        dp = DatasetProject.create(:project => project,
                                   :dataset => dataset)
      end
    end
  end

  def self.down
  end
end
