# A Role is the actual role that a Person plays in the scope of a certain Project. To achieve some standardization, these roles are defined in this model.
# They are bound to a Person with a PersonRole.

class Role < ActiveRecord::Base

  acts_as_authorization_role :subject_class_name => 'Person', :join_table_name => 'roles_people'

  def to_label
    if self.authorizable
      "#{self.name} FOR #{self.authorizable} "
    else
      self.name
    end
  end
  #has_many :person_roles

  #validates_presence_of :name
  #validates_uniqueness_of :name

  ## if a role is deleted, the associated person roles should get other roles,
  ## so that they still are useful
  ## before or after destroy


  def authorized_for_create? # :nodoc:
    if current_user
      return true if current_user.has_role?('admin')
    else
      return false
    end
  end

  def authorized_for_read? # :nodoc:
    if current_user
      return true if current_user.has_role?('admin')
    else
      return false
    end
  end

  def authorized_for_update? # :nodoc:
    if current_user
      return true if current_user.has_role?('admin')
    else
      return false
    end
  end

  def authorized_for_destroy? # :nodoc:
    if current_user
      return true if current_user.has_role?('admin')
    else
      return false
    end
  end
end
