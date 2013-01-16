class User < ActiveRecord::Base
  acts_as_authentic
  acts_as_authorization_subject  association_name: "roles", join_table_name: "roles_users"

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

  belongs_to :project

  # setting up avatar-image
  validates_attachment_content_type :avatar, :content_type => /image/, :if => :avatar_file_name_changed?,
                            :message => "is invalid. Must be a picture such as jpeg or png."

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

  before_save :change_avatar_file_name, :add_protocol_to_url

  def change_avatar_file_name
    if avatar_file_name && avatar_file_name_changed?
      new_name = "#{id}_#{lastname}#{File.extname(avatar_file_name).downcase}"
      if avatar_file_name != new_name
        self.avatar.instance_write(:file_name, new_name)
      end
    end
  end

  def add_protocol_to_url
    unless self.url.blank?
      /^http/.match(self.url) ? self.url : self.url = "http://#{url}"
    end
  end

  def to_label
    if !salutation.blank?
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
    "#{id}-#{firstname}_#{lastname}".gsub(/[\s]/, '')
  end

  # This method provides a nice look of Person on some pages
  def full_name
    "#{lastname}, #{firstname} - #{salutation}"
  end

  # nice strings for citations etc.
  def short_name
    firstnames_short = firstname.split(" ").collect{|fn| "#{fn[0]}."}.join(", ")
    "#{lastname}, #{firstnames_short}"
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

  def data_admin
    self.has_role? :data_admin
  end

  def data_admin=(string_boolean)
    if string_boolean == "1"
      self.has_role! :data_admin
    else
      self.has_no_role! :data_admin
    end
  end

  def datasets_owned
    Dataset.all.select{|ds| ds.accepts_role?(:owner, self)}
  end

  def datasets_with_responsible_datacolumns_not_owned
    # there must be a better way of doing this but it works for now

    # find all the datacolumns that this user is responsible for
    # and select all the datasets that the datacolumns are part of
    @columns = Datacolumn.all.select { |ds| ds.accepts_role?(:responsible, self)}
    if(@columns.count>0)
      @columnids = @columns.map{|col| col.dataset_id}
      if (@columns.count==1)
        #Dataset.find(:all, :conditions => ["id = ?", @columnids])
        @predicate = "id=#{@columnids[0]}"
      else
        @predicate = "id in (#{@columnids.join(",")})"
        #Dataset.find(:all, :conditions => ["id in (?)", @columnids])
      end
      # get the datasets this user owns
      # and do not select them in the query
      @owned = self.datasets_owned
      if(@owned.count >0)
        @ownedids = @owned.map{|ds| ds.id}
        if(@owned.count==1)
          @predicate = @predicate + " and id !=#{@ownedids[0]}"
        else
          @predicate = @predicate + " and id not in (#{@ownedids.join(",")})"
        end
      end
      # return all the datasets for the predicate
      Dataset.find(:all, :conditions => [@predicate])
    else
      # return an empty array
      Array.new
    end
  end

  def paperproposals
    (paperproposals_author_table + owning_paperproposals).uniq.sort
  end

  def projectroles
    # return the project roles that this user has
    # disclude any admins roles
    @projectsarray = []
    @index =0
    for role in self.role_objects.reject{|r| r.name == "admin"}
      if(role.authorizable.class.to_s == "Project")
        @projectsarray[@index]= role
        @index = @index +1
      end
    end
    @projectsarray
  end

  def authorized_for_update?
    if (self == current_user || current_user.has_role?("admin")) then
      true
    else
      false
    end
  end

  def open_votes_count
    self.paperproposal_votes.where("vote = 'none'").count
  end

  def self.all_users_names_and_ids_for_select
    User.all(:order => :lastname).collect {|person| [person.to_label, person.id]}
  end

  def pi
    projects = self.roles_for(Project).map(&:authorizable)
    projects.map(&:pi).flatten
  end

  def self.email_list(users_array)
    users_array.collect{|u| Hash[:name, "#{u.firstname} #{u.lastname}", :mail, "#{u.email}"]}
  end

end



