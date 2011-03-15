# A project is actually a sub-project of the whole BEF project.

class Project < ActiveRecord::Base
  acts_as_authorization_object :subject_class_name => 'User'

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

end
