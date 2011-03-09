class ContextFreeproject < ActiveRecord::Base
  belongs_to :context
  belongs_to :project

  validates_presence_of :project_id, :context_id
  validates_uniqueness_of :project_id, :scope => :context_id

#  validates_associated :context, :project


end
