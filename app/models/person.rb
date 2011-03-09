# This file maps the people table in the data base.

require 'digest/sha1'

# Person stores all informations about the people in the system.
class Person < ActiveRecord::Base

  # !!! We will have to enable the possibility to create a person
  # !!! without having to specify a password.  This person then cannot
  # !!! login, but that is ok, these will be external people.  At the
  # !!! moment one has to provide login, password, as well as password
  # !!! information, but this is only true for members of the research
  # !!! unit.
  include Authentication
  include Authentication::ByPassword
  include Authentication::ByCookieToken

  acts_as_authorization_subject :join_table_name => "roles_people", 
    :role_class_name => 'Role'


  include FuzzySearch
  fuzzy_search_attributes :firstname, :lastname

  has_many :person_addresses, :dependent => :destroy
  #has_many :roles, :through => :person_roles
  has_many :person_roles # only if this person has no person roles associated to any
  # context or submethod, :dependent => :destroy
  ## must be done, since otherwise a person can be deleted which has
  ## person roles
  has_many :context_freepeople, :dependent => :destroy

  #Todo really dependent destroy?
  has_many :data_request_votes, :dependent => :destroy
  has_many :project_board_votes, :class_name => "DataRequestVote",
           :source => :data_request_votes, :conditions => {:project_board_vote => true }
  has_many :for_data_request_votes, :class_name => "DataRequestVote",
           :source => :data_request_votes, :conditions => {:project_board_vote => false }

  validates_presence_of :lastname, :firstname
  validates_uniqueness_of   :login
  
  # tagging
  is_taggable :tags, :languages

  after_destroy :destroy_taggings

  # List the Projects (Project) a Person is associated to
  def projects
# die conditions greifen nicht in dieser Abfrage ...
#    roles = self.role_objects :conditions => [:authorizable_type => 'Project']
    roles = self.role_objects.select{|rob| rob.authorizable_type=="Project"}
    roles.map{|role| role.authorizable}    
  end

  def destroy_taggings
    logger.debug "in destroy taggings"
    self.taggings.destroy_all
  end


  # This method provides a nice look of Person in admin views
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
  
  # This method provides a nice look of Person on some pages
  def path_name
    "#{firstname}_#{lastname}"
  end

  # This method provides a nice look of Person on some pages
  def full_name
    "#{lastname}, #{firstname} - #{salutation}" 
  end
  
  # Checks, wether this Person has a specific role in one of its PersonRole
#  def has_role?(role)
#    r = []
#    person_roles = self.person_roles
#    if person_roles.length > 0
#      person_roles.each do |pr|
#        unless pr.role.blank?
#          r << true if pr.role.name == role
#        end
#      end
#    else
#      r << false
#    end
#
#    if r.include?(true)
#      return true
#    else
#      return false
#    end
#  end
  
  # Returns all addresses of this Person
  def addresses
    add = {:phones => [], :mails => [], :urls => [], :comments => []}
    self.person_addresses.each do |a|
      add[:phones] << a.phone.to_s unless a.phone.blank?
      add[:mails] << a.email.to_s unless a.email.blank?
      add[:urls] << a.url.to_s unless a.url.blank?
      add[:comments] << a.comment.to_s unless a.comment.blank?
    end
    return add
  end

  # Virtual column for displaying a password field in admin
  # backend. Password is actually never shown.
  def pwd
    ""
  end

  # Virtual column for entering password in admin backend.
  def pwd=(new_password)
    self.crypted_password = encrypt(new_password) 
  end
  
  # Authenticates a user by their login name and unencrypted password.
  # Returns the user or nil.
  def self.authenticate(login, password)
    return nil if login.blank? || password.blank?
    u = find_by_login(login.downcase) # need to get the salt
    u && u.authenticated?(password) ? u : nil
  end

  # Virtual column for entering a username in admin backend. Provides
  # the additional posibility to delete the login.
  def login=(value)
    write_attribute :login, (value ? value.downcase : nil)
  end

  #########################
  # Active Scaffold Methods
  #########################
  def authorized_for_create? # :nodoc:
    if current_user
      return true if current_user.has_role?('admin')
    else
      return false
    end
  end

  def authorized_for_read? # :nodoc:
    if current_user
      return true unless existing_record_check?
      return true if current_user.has_role?('admin') || current_user == self
    else
      return false
    end
  end

  def authorized_for_update? # :nodoc:
    if current_user
      return true unless existing_record_check?
      return true if current_user.has_role?('admin') || current_user == self
    else
      return false
    end
  end

  def authorized_for_destroy? # :nodoc:
    if current_user
      return true if current_user.has_role?('admin')
    else
      return false
    end
  end

end
