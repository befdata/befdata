class User < ActiveRecord::Base
  acts_as_authentic
  acts_as_authorization_subject  :association_name =>:roles, :join_table_name => :roles_users

  validates_presence_of :lastname, :firstname
  validates_uniqueness_of :login

  # related paperproposals. Roles include: proponent, main aspect dataset owner, side aspect dataset owner, acknowledged.
  has_many :author_paperproposals, :dependent => :destroy, :include => [:paperproposal]
  has_many :paperproposals_author_table, :through => :author_paperproposals,:source => :paperproposal
  # paperproposals created by the user
  has_many :owning_paperproposals, :class_name => "Paperproposal",:foreign_key => "author_id"

  has_many :paperproposal_votes, :dependent => :destroy  #Todo really dependent destroy?

  has_many :project_board_votes, :class_name => "PaperproposalVote",
           :source => :paperproposal_votes, :conditions => {:project_board_vote => true }
  has_many :for_paperproposal_votes, :class_name => "PaperproposalVote",
           :source => :paperproposal_votes, :conditions => {:project_board_vote => false }

  has_many :notifications

  belongs_to :project

  has_attached_file :avatar,
    :url => "/images/user_avatars/:basename_:style.:extension",
    :default_url => "/images/user_avatars/avatar-missing_:style.png",
    :path => ":rails_root/public/images/user_avatars/:basename_:style.:extension",
    :default_style => :small,
    :styles => {
      :small => "50x50#",
      :medium => "80x80#",
      :large => "150x150#"
  }

  validates_attachment_content_type :avatar, :content_type => /image/, :if => :avatar_file_name_changed?,
                            :message => "is invalid. Must be a picture such as jpeg or png."


  before_save :change_avatar_file_name, :add_protocol_to_url
  before_destroy :check_destroyable

  def to_s
    if salutation.blank?
      "#{firstname} #{lastname}"
    else
      "#{firstname} #{lastname}, #{salutation}"
    end
  end
  alias to_label to_s

  def to_param
    "#{id}-#{full_name}".parameterize
  end

  def full_name
    "#{firstname} #{lastname}"
  end

  # nice strings for citations etc.
  def short_name
    firstnames_short = firstname.split(" ").collect{|fn| "#{fn[0]}."}.join(", ")
    "#{lastname}, #{firstnames_short}"
  end

  def email_with_name
    "#{full_name} <#{email}>"
  end

  %w{admin data_admin project_board}.each do |role|
    define_method(role) do
      self.has_role? role.to_sym
    end

    define_method("#{role}=") do |value|
      case value
      when true, 1, '1'
        self.has_role! role.to_sym
      when false, 0, '0'
        self.has_no_role! role.to_sym
      end
    end

    define_singleton_method("all_#{role}s") do
      Role.find_by_name(role).users
    end
  end

  def datasets_owned
    self.roles.includes(:authorizable).where({name: "owner", authorizable_type: "Dataset"}).map(&:authorizable).compact
  end

  def datasets_with_responsible_datacolumns
    columns = self.roles_for(Datacolumn).map(&:authorizable_id)
    unless columns.empty?
      dataset_ids = Datacolumn.where(:id => columns).pluck(:dataset_id)
      datasets = Dataset.find(dataset_ids)
      return datasets
    end
    return Array.new
  end

  def paperproposals
    owning_paperproposals | paperproposals_author_table
  end

  def destroyable?
    (datasets_owned.count + paperproposals.count + datasets_with_responsible_datacolumns.count).zero?
  end

  def projects
    roles_for(Project).map(&:authorizable)
  end

  def projectroles
    self.roles_for(Project)
  end

  def projectroles=(roles_config)
    # roles_config is an array of hashes like {role_name: "pi", project_id: 3}
    self.has_no_roles_for!(Project)
    return if roles_config.blank?
    roles_config.each do |role|
      self.has_role!(role[:role_name], Project.find(role[:project_id])) unless role[:project_id].blank?
    end
  end

  def open_votes_count
    self.paperproposal_votes.where("vote = 'none'").count
  end

  private

  def change_avatar_file_name
    if avatar_file_name && avatar_file_name_changed?
      new_name = "#{id}_#{lastname}#{File.extname(avatar_file_name).downcase}"
      if avatar_file_name != new_name
        self.avatar.instance_write(:file_name, new_name)
      end
    end
  end

  def add_protocol_to_url
    if self.url.present? and self.url_changed?
      /^http/.match(self.url) ? self.url : self.url = "http://#{url}"
    end
  end

  def check_destroyable
    unless destroyable?
      errors.add(:base, "#{full_name} still owns some resources, thus can not be deleted!")
      return false
    end
  end
end
