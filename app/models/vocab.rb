class Vocab < ActiveRecord::Base
  attr_accessible :term
  validates_presence_of :term
  validates_uniqueness_of :term

  has_many :datacolumns, :foreign_key => :term_id, :dependent => :nullify
end
