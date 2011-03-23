module Admin::UsersHelper

  def roles_without_objects_column(record)
    record.role_objects.reject{|role_object| !role_object.authorizable_type.nil?}.
        map{|role_object| role_object.name}.join(", ")
  end

#
#  def omnipotent_form_column(record, name)
#    check_box :record, :omnipotent, :name => name
#  end

  def roles_with_objects_column(record)
    record.role_objects.reject{|role_object| role_object.authorizable_type.nil?}.
        map{|role_object| "#{role_object.name} of #{role_object.authorizable_type} with id: #{role_object.authorizable_id}"}.join(", ")
  end
end
