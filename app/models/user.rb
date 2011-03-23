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

  def to_s # :nodoc:
    to_label
  end

  def projects
  # die conditions greifen nicht in dieser Abfrage ...
  #    roles = self.role_objects :conditions => [:authorizable_type => 'Project']
    roles = self.role_objects.select{|rob| rob.authorizable_type=="Project"}
    roles.map{|role| role.authorizable}
  end

  # This method provides a nice look of Person on some pages
  def path_name
    "#{firstname}_#{lastname}"
  end

  # This method provides a nice look of Person on some pages
  def full_name
    "#{lastname}, #{firstname} - #{salutation}"
  end

  def add_role=(role)
    unless role.nil? || role.empty?
      self.has_role! role.to_sym
    end
  end

  def add_role
    nil
  end

end
