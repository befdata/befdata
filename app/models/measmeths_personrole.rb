# MeasmethsPersonrole links people (PersonRole, Person) to
# MeasurementsMethodstep, which links to the methods (Method,
# Methodstep) used.

class MeasmethsPersonrole < ActiveRecord::Base
  belongs_to :person_role
  belongs_to :measurements_methodstep

  def to_s # :nodoc:
    to_label
  end

  # This method provides a nice look of MeasmethsPersonrole in admin views
  def to_label
    "Person role for #{measurements_methodstep.columnheader}"
  end

  def authorized_for_create? # :nodoc:
    if current_user
      return true if current_user.has_role?('admin')
    else
      return false
    end
  end

  def authorized_for_read? # :nodoc:
    if current_user
      return true
    else
      return false
    end
  end

  def authorized_for_update? # :nodoc:
    if current_user
      return true
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
