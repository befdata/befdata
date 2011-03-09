class ContextFreeperson < ActiveRecord::Base
  belongs_to :context
  belongs_to :person

  validates_presence_of :person_id, :context_id
  validates_uniqueness_of :person_id, :scope => :context_id
  ## so if we say where the id is, there also must be a valid object then:
  ## validates_associated :context, :person
  ## this means, before a ContextFreeperson can be saved, the Person as well
  ## as the context has already to be valid

end
