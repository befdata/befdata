# An Institution is the organization that a specific Person works for. It is bound to the person via PersonRole, because one may work for different institutions 
# in different roles. 

class Institution < ActiveRecord::Base
  has_many :person_roles

  validates_presence_of :name, :city
  validates_uniqueness_of :name, :scope => :city

  ## if an Institution is destroyed, and if it is associated to a
  ## person role, the institution id in person role should be set to nil
  ## -> after destroy



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
