module Admin::UsersHelper


  def roles_without_objects_column(record)
    record.role_objects.reject{|role_object| !role_object.authorizable_type.nil?}.
        map{|role_object| role_object.name}.join(", ")
  end

  def admin_form_column(record, name)
    check_box :record, :admin
  end

  def project_board_form_column(record, name)
    check_box :record, :project_board
  end

  def roles_with_objects_column(record)
    record.role_objects.reject{|role_object| role_object.authorizable_type.nil?}.
        map{|role_object| "#{role_object.name} of #{role_object.authorizable_type} with id: #{role_object.authorizable_id}"}.join(", ")
  end


end
