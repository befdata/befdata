# A project is actually a sub-project of the whole BEF project.
require 'acl_patch'
class Project < ActiveRecord::Base
  acts_as_authorization_object :subject_class_name => 'User'
  include AclPatch

  has_and_belongs_to_many :datasets
  has_many :authored_paperproposals, :class_name => "Paperproposal",  :foreign_key => :project_id

  validates_presence_of :shortname, :name
  validates_uniqueness_of :shortname, :name

  def to_s
    "#{name}"
  end
  alias to_label to_s

  def to_tag
    Project.create_tag self.shortname
  end

  def self.find_by_converting_to_tag (project_tag)
    project_tag = Project.create_tag project_tag
    Project.select {|p| p.to_tag == project_tag}
  end

  def self.create_tag (string)
    # "P1 Europe productivity" becomes "p1e"
    # downcase, erase non-numbers and non-letters, cut after first letter behind possible numbers
    string.downcase.scan(/[^\W]/).join.slice(/^\D+\d*\D/)
  end

  def pi
    get_user_with_role(:pi)
  end

  def destroyable?
    (self.datasets.count + self.users.count + self.authored_paperproposals.count) == 0
  end

  before_destroy :check_destroyable
  def check_destroyable
    unless destroyable?
      errors.add(:base, "#{shortname} still owns some resources, thus can not be deleted!")
      return false
    end
  end

end
