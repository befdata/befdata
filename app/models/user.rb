
class User < ActiveRecord::Base
  acts_as_authentic
  acts_as_authorization_subject

  validates_presence_of :lastname, :firstname
  validates_uniqueness_of   :login


  #Todo really dependent destroy?
  has_many :paperproposal_votes, :dependent => :destroy
  has_many :project_board_votes, :class_name => "PaperproposalVote",
           :source => :paperproposal_votes, :conditions => {:project_board_vote => true }
  has_many :for_paperproposal_votes, :class_name => "PaperproposalVote",
           :source => :paperproposal_votes, :conditions => {:project_board_vote => false }

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

  def admin
    self.has_role? :admin
  end

  def admin=(string_boolean)
    if string_boolean == "1"
      self.has_role! :admin
    else
      self.has_no_role! :admin
    end
  end

  def project_board
    self.has_role? :project_board
  end

def project_board=(string_boolean)
    if string_boolean == "1"
      self.has_role! :project_board
    else
      self.has_no_role! :project_board
    end
  end


end
