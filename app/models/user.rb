class User < ActiveRecord::Base
  acts_as_authentic

  validates_presence_of :lastname, :firstname
  validates_uniqueness_of   :login
end
