# A project is actually a sub-project of the whole BEF project.

class Project < ActiveRecord::Base
  acts_as_authorization_object :subject_class_name => 'User'

  has_and_belongs_to_many :datasets

  has_many :authored_paperproposals, :class_name => "Paperproposal",  :foreign_key => :project_id

  validates_presence_of :shortname, :name
  validates_uniqueness_of :shortname, :name

  def to_label
    "#{name}"
  end

  def to_s # :nodoc:
    to_label
  end

  def self.all_projects_for_select
    Project.all(:order => :shortname).collect{|p| [p.to_label, p.id]}
  end

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
    self.accepted_roles.find_by_name("pi").try(:users)
  end
end
