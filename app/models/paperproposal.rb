# This file contains the Paperproposal model definition. Paperproposals are used for organizing data exchange.

# Paperproposals assemble the Dataset instances (DatasetPaperproposal) )that are
# needed for a particular purpose, in most cases
# a scientific analysis. *Proponents* of the paperproposal are those users (User) that have submitted
# the paperproposal.
#
# Proponents submit proposals to the project board (see Role) for approval as well as hints and tips
# and then to the owners of datasets for the permission to use the data.
#
# Datasets can be of main or side aspect for the proposal. Dataset owners of main aspect datasets
# should be offered a co-authorship in the resulting paper.
class Paperproposal < ActiveRecord::Base

  # acts_as_authorization_object :subject_class_name => 'Project'

  belongs_to :author, :class_name => "User", :foreign_key => "author_id"

  belongs_to :authored_by_project, :class_name => "Project", :foreign_key => :project_id

  # User roles in a paperproposal: proponents, main aspect dataset owner, side aspect dataset owner, acknowledged.
  # many-to-many association with User model through author_paperproposal joint table.
  has_many :author_paperproposals, :dependent => :destroy, :include => [:user]
  has_many :authors, :class_name => "User", :source => :user, :through => :author_paperproposals
  # with four conditional association.
  has_many :proponents, :class_name => "User", :source => :user, :through => :author_paperproposals, :conditions => ['kind=?',"user"]
  has_many :main_aspect_dataset_owners, :class_name => "User", :source => :user, :through => :author_paperproposals, :conditions => ['kind=?',"main"]
  has_many :side_aspect_dataset_owners, :class_name => "User", :source => :user, :through => :author_paperproposals, :conditions => ['kind=?',"side"]
  has_many :acknowledgements_from_datasets, :class_name => "User", :source => :user, :through => :author_paperproposals, :conditions => ['kind = ?', 'ack']

  # User votes on a paperproposal.
  # has_many association with paperproposal_votes model.
  # two conditional association to differentiate project board vote and dataset request vote.(FIXME: dataset owner's vote?)
  has_many :paperproposal_votes, :dependent => :destroy
  has_many :project_board_votes, :class_name => "PaperproposalVote",
           :source => :paperproposal_votes, :conditions => {:project_board_vote => true }
  has_many :for_data_request_votes, :class_name => "PaperproposalVote",
           :source => :paperproposal_votes, :conditions => {:project_board_vote => false }
  # has_many through association with User model via paperproposal_votes joint table.
  has_many :coordinators, :class_name => "User", :source => :user, :through => :paperproposal_votes,
           :conditions => ['project_board_vote = ?',true]

  # habtm association with Dataset model.
  has_many :dataset_paperproposals, :dependent => :destroy
  has_many :datasets, :through => :dataset_paperproposals

  # one-to-many association with Freeformat model.
  has_many :freeformats, :as => :freeformattable, :dependent => :destroy

  scope :has_state, lambda{|s| where(:state=>s)}
  accepts_nested_attributes_for :authors

  validates_presence_of :title, :rationale

  STATES = {
    # for the sorting
    'accepted' => 1,
    'in review' => 2,
    'manuscript avaible' => 3,
    'in prep' => 4
  }
  KIND = {"user"=>"Proponent",
          "main"=>"Main aspect data provider",
          "side"=>"Side aspect data provider",
          "ack" =>"Acknowledged"
  }

  def <=>(other)
    # sort by state, then by year if published, then title
    x = STATES[self.state] <=> STATES[other.state]
    x = (x != 0 ? x : self.envisaged_date.year <=> other.envisaged_date.year) if self.state == 'accepted'
    x = (x != 0 ? x : self.beautiful_title(true) <=> other.beautiful_title(true))
    x = (x != 0 ? x : self.title.downcase <=> other.title.downcase)
    x
  end

  def calc_board_state
    return "In Preparation, no data selected yet." if self.board_state == "prep" && self.datasets.length == 0
    return "still no aspects set" if self.board_state == "prep" && !check_aspects_for_contexts
    return "complete" if self.board_state == "prep" && check_aspects_for_contexts
    return "Submitted to board, waiting for acceptance." if self.board_state == "submit"
    return "Project Board rejected your data request. Please make changes and submit again." if self.board_state == "re_prep"
    return "accept" if self.board_state == "accept"
    return "final" if self.board_state == "final"
  end

  def author_list(include_pi=false)
    # Do we still need senior author in author list?
    senior_author = include_pi ? self.author.try(:pi) : []
    ack = self.acknowledgements_from_datasets
    middle_block = self.authors - ack - [self.author] - senior_author
    middle_block.uniq!
    middle_block.sort!{|a,b| a.lastname <=> b.lastname}

    author_list = [self.author, middle_block, senior_author]
    author_list.flatten!
    author_list.uniq!

    ack -= author_list
    ack = ack.uniq.sort{|a,b| a.lastname <=> b.lastname}

    {:author_list => author_list, :ack => ack}
  end

  def calc_authorship(user)
    authorship = []
    if(user.id == self.author_id)
      authorship << "Author"
    end
    roles = self.author_paperproposals.where(:user_id=>user.id).map(&:kind)
    roles.each{|r| authorship<< KIND[r]}
    return authorship.to_sentence
  end

  def beautiful_title (only_authors = false)
    # gives back a nice string to display, like: Kraft, N. J., Comita, L. S. (2011): DisentanglingAlong Latitudinal and Elevational Gradients. Science, 333(6050).

    pp_hash = Hash.new
    pp_hash['pp_project_short_name'] = self.authored_by_project.blank? ? "" : "#{self.authored_by_project.shortname}, "
    pp_hash['pp_author'] = "#{self.author.short_name}: "
    return authors if only_authors

    pp_hash['pp_year'] = self.envisaged_date.year.blank? ? "" : "#{self.envisaged_date.year}, "
    pp_hash['pp_title'] = self.title.blank? ? "" : "#{self.title}, "
    pp_hash['pp_journal'] = self.envisaged_journal.blank? ? "" : ", Citation: #{envisaged_journal}"

    proponents_and_dataowners_array = []
    self.authors_selection(:proponents_and_all_owners).each do |p|
      proponents_and_dataowners_array << p.firstname + " " + p.lastname
    end

    proponents_and_dataowners_array = proponents_and_dataowners_array.sort
    pp_hash['pp_proponents_and_dataowners'] = proponents_and_dataowners_array.blank? ? "" : "Proponents and dataowners: #{proponents_and_dataowners_array.split.join(", ")}"

    # "#{pp_project_short_name} #{pp_author} #{pp_year} #{pp_title} #{pp_proponents_and_dataowners} #{pp_journal}"
    "#{ pp_hash["pp_project_short_name"]} #{pp_hash["pp_author"]} #{pp_hash["pp_year"]} #{pp_hash["pp_title"]} #{pp_hash["pp_proponents_and_dataowners"]} #{pp_hash["pp_journal"]}"
  end

  def calculate_datasets_proponents
    all_proponents = {:main => [], :side => [], :ack => []}
    # collect relevant users
    self.dataset_paperproposals.each do |ds_pp|
      dataset = ds_pp.dataset
      ds_pp.aspect = 'main' if ds_pp.aspect.blank? #some have no aspect set
      all_proponents[ds_pp.aspect.to_sym] << dataset.owners
      all_proponents[:ack] << dataset.datacolumns.map{|dc| dc.users}
    end

    #clear out the old ones
    AuthorPaperproposal.delete_all(["paperproposal_id = ? AND (kind = ? OR kind = ? OR kind = ?)", self.id, 'main', 'side', 'ack'])

    #reassign
    new_author_paperproposals = []
    all_proponents.each do |aspect, user_array|
      user_array.flatten!
      user_array.uniq!
      new_author_paperproposals <<
          user_array.map{ |u| AuthorPaperproposal.new(:user => u, :paperproposal => self, :kind => aspect.to_s)}
    end
    new_author_paperproposals.flatten!
    self.author_paperproposals << new_author_paperproposals
    self.save
  end

  def all_authors_ordered(focus = nil)
    categorized_authors = [[self.author], self.proponents]
    unless focus == :without_data
      categorized_authors << self.main_aspect_dataset_owners
      categorized_authors << self.side_aspect_dataset_owners
      categorized_authors << self.acknowledgements_from_datasets
    end
    ordered_authors = []
    categorized_authors.each do |cat|
      cat.sort_by!(&:lastname)
      cat.each do |user|
        ordered_authors << user unless ordered_authors.include?(user)
      end
    end
    ordered_authors
  end

  def authors_selection(specific_selection)
    result = case specific_selection
               when :author_and_proponents then [author] + proponents
               when :proponents_and_main then [author] + proponents + main_aspect_dataset_owners
               when :proponents_and_all_owners then [author] + proponents + main_aspect_dataset_owners + side_aspect_dataset_owners
               when :all_mentioned then [author] + proponents + main_aspect_dataset_owners + side_aspect_dataset_owners + acknowledgements_from_datasets
            end
    result.flatten.uniq
  end

  private

  def check_aspects_for_contexts
    if self.datasets.length >= 0
      self.dataset_paperproposals.each do |dgdr|
        if dgdr.aspect.nil? || dgdr.aspect.empty?
          return false
        end
      end
      return true
    end
    return false
  end

end
