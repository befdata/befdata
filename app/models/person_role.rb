# PersonRole is a pivot for Person, Project, and Institution. It is
# used by many different tables, it may be linked to many
# ContextPersonRole, MesmethsPersonrole, or even Measurement
# entries. It gives information on
# * the role a Person is playing in a given context
#
# inspired by the eml category "party"
# http://knb.ecoinformatics.org/software/eml/eml-2.1.0/eml-party.html

class PersonRole < ActiveRecord::Base

  belongs_to :person
  belongs_to :role
  belongs_to :project
  belongs_to :institution  # if not used otherwise, dependent destroy
  has_many :contexts, :through => :context_person_roles
  has_many :context_person_roles
  has_many :measmeths_personroles
  has_many :measurements, :as => :value
  


  #validates_presence_of :person_id, :project_id, :role_id
  
  def to_s # :nodoc:
    "#{role}"
  end
  
  # This method provides a nice look of PersonRole in admin views
  def to_label
    if role
      "#{person.full_name}/#{project} (Role: #{role.name})"
   else
      "#{person.full_name}/#{project} (No role set)"
   end
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
      return true unless existing_record_check?
      return true if current_user.has_role?('admin') || current_user == self.person
    else
      return false
    end
  end

  def authorized_for_update? # :nodoc:
    if current_user
      return true unless existing_record_check?
      return true if current_user.has_role?('admin') || current_user == self.person
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

  def before_destroy
    ## look if it is associated to any submethods or contexts
    ## Fehlermeldung, falls das der Fall ist
  end
end
