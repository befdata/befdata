# A Person can have one or many addresses.  This includes url, phone, and
# e-mail.   !! This table should also include another attribute: publish
# (yes/no).  If publish is set to "yes", it means that contact information 
# is published on the pages accessible for the public.  In this case,
# information should not be machine readable but there should be spaces
# interspersed.


class PersonAddress < ActiveRecord::Base
  belongs_to :person

  validates_presence_of :person_id

  # This method provides a nice look of PersonAddress in admin views
  def to_label
    "Addresses of #{self.person.full_name}"
  end
  
  def to_s # :nodoc:
    to_label
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
