class User < ActiveRecord::Base
  acts_as_authentic
  acts_as_authorization_subject

  validates_presence_of :lastname, :firstname
  validates_uniqueness_of   :login


  def to_label
    if salutation
      "#{firstname} #{lastname}, #{salutation}"
    else
      "#{firstname} #{lastname}"
    end
  end
end
