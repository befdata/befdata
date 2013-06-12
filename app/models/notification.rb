class Notification < ActiveRecord::Base
  belongs_to :user

  validates_presence_of :user, :subject
  attr_accessible :message, :read, :subject, :user_id
end
