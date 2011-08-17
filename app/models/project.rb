# A project is actually a sub-project of the whole BEF project.

class Project < ActiveRecord::Base
  acts_as_authorization_object :subject_class_name => 'User'

  # acts_as_authorization_subject

  has_many :dataset_projects
  has_many :datasets, :through => :dataset_projects
  has_many :authored_paperproposals, :class_name => "Paperproposal",  :foreign_key => :project_id

  validates_presence_of :shortname, :name
  validates_uniqueness_of :shortname, :name

  def to_label
    "#{name}"
  end

  def to_s # :nodoc:
    to_label
  end


end
