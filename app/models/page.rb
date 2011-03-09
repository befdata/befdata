# A page is a simple text field that resides in the database. Pages can be edited via the WYSIWYG editor in the admin backend. Their name is not changeable,
# as this would break the page calls from some actions.
class Page < ActiveRecord::Base

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
