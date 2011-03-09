# ContextPersonRole links a Context to a PersonRole.

class ContextPersonRole < ActiveRecord::Base
  belongs_to :context
  belongs_to :person_role

  validates_presence_of :person_role_id, :context_id
  validates_uniqueness_of :person_role_id, :scope => :context_id
  ## validates_associated :person_role, :context
  ## This will make trouble. It means that a context first has to be saved and
  # then all this can be validated
  
  
  def to_s # :nodoc:
    to_label
  end

  # This method provides a nice look of ContextPersonRole in admin views
  def to_label
    if context
      "Person role for #{context.title}"
    else
      "No context title given"
    end
  end

  def authorized_for_create? # :nodoc:
    if current_user
      return true unless existing_record_check?
      return true if current_user.has_role?('admin') || self.context.context_person_roles.map{|cpr| cpr.person_role.person}.uniq.include?(current_user)
    else
      return false
    end
  end

  def authorized_for_read? # :nodoc:
    if current_user
      return true #if current_user.has_role?('admin')
    else
      return false
    end
  end

  def authorized_for_update? # :nodoc:
    if current_user
      return true #if current_user.has_role?('admin')
    else
      return false
    end
  end

  def authorized_for_destroy? # :nodoc:
    if current_user
      return true unless existing_record_check?
      return true if current_user.has_role?('admin') || self.context.context_person_roles.map{|cpr| cpr.person_role.person}.uniq.include?(current_user)
    else
      return false
    end
  end
end
