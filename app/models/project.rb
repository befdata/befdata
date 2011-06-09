# A project is actually a sub-project of the whole BEF project.

class Project < ActiveRecord::Base
  acts_as_authorization_object :subject_class_name => 'User'

  acts_as_authorization_subject

  has_many :dataset_projects
  has_many :authored_paperproposals, :class_name => "Paperproposal",  :foreign_key => :project_id

  validates_presence_of :shortname, :name
  validates_uniqueness_of :shortname, :name

  ## projects should not be able to destroy, if they own data; if they acquired
  ## download rights, those may be destroyed toghether with the projects
  ## def before_destroy

  # This method provides a short but descriptive string for the
  # project instance.

#  # tagging
#  is_taggable :tags, :languages
#
#  after_destroy :destroy_taggings
#
#  def destroy_taggings
#    logger.debug "in destroy taggings"
#    self.taggings.destroy_all
#  end
  

  def query_by_role(role_name)
  #corresponding_role_ids = self.accepted_roles.all(:conditions => { :name => role_name }).map(&:id)

  # this will now return all users that have +role_name+ on +object+
  #Person.all(:conditions => ['roles.id IN (?)', corresponding_role_ids])
  self.users.select{|person| person.has_role? role_name, self}
  end

  def to_label
    "#{name}"
  end

  def to_s # :nodoc:
    to_label
  end


  def user_for_role; end
  def user_for_role=; end

  def add_role_for_user

  end

  def datasets_owned
    Dataset.all.select { |ds| ds.accepts_role?(:owner, self)}
  end

  def paperproposals_owned
    Paperproposal.all.select { |pp| pp.accepts_role?(:owner, self)}
  end

end
