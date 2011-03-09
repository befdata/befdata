# A project is actually a sub-project of the whole BEF project.

class Project < ActiveRecord::Base

  ##################################################################################
  # Here the Roles a Person could have to this Object:                             #
  # :pi, :co_pi, :phd, :funding_source, :post_doc, :speaker, :student, :technician #
  ##################################################################################
  acts_as_authorization_object :subject_class_name => 'Person', :role_class_name => 'Role'

  #has_many :person_roles
  has_many :context_freeprojects

  validates_presence_of :shortname, :name
  validates_uniqueness_of :shortname, :name

  ## projects should not be able to destroy, if they own data; if they acquired
  ## download rights, those may be destroyed toghether with the projects
  ## def before_destroy
  
  # This method provides a short but descriptive string for the
  # project instance.

  # tagging
  is_taggable :tags, :languages

  after_destroy :destroy_taggings

  def query_by_role(role_name)
  #corresponding_role_ids = self.accepted_roles.all(:conditions => { :name => role_name }).map(&:id)

  # this will now return all users that have +role_name+ on +object+
  #Person.all(:conditions => ['roles.id IN (?)', corresponding_role_ids])
  self.people.select{|person| person.has_role? role_name, self}
  end

  def destroy_taggings
    logger.debug "in destroy taggings"
    self.taggings.destroy_all
  end


  def to_label
    "#{name}"
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
