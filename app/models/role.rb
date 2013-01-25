class Role < ActiveRecord::Base
  acts_as_authorization_role subject_class_name: "User", join_table_name: "roles_users"
end
