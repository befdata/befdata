module Admin::ProjectsHelper

  def users_with_roles_for_form_column(record)
    record.accepted_roles
  end

end
