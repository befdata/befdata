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

  belongs_to :project

  # setting up avatar-image
  validates_attachment_content_type :avatar, :content_type => ['image/jpeg','image/png']

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

  before_save :change_avatar_file_name

  def change_avatar_file_name
    if avatar_file_name
      new_name = "#{id}_#{lastname}#{File.extname(avatar_file_name).downcase}"
      if avatar_file_name != new_name
        self.avatar.instance_write(:file_name, new_name)
      end
    end
  end

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

  def datasets_owned
    Dataset.all.select { |ds| ds.accepts_role?(:owner, self)}
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

  def paperproposal_author
    # return the paper proposals that this user is an author, senior author or corresponding author for
    Paperproposal.find(:all,
                       :conditions => ["author_id=? or corresponding_id=? or senior_author_id=?",
                                       self.id, self.id, self.id])
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




end



