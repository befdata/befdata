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
  before_destroy :reset_download_rights # needs to be before association definition,see https://rails.lighthouseapp.com/projects/8994/tickets/4386
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
    return 'in preparation, no data selected' if self.board_state == 'prep' && self.datasets.length == 0
    return 'still no aspects set' if self.board_state == 'prep' && !check_aspects_for_contexts
    return 'can be send to project board' if self.board_state == 'prep' && check_aspects_for_contexts
    return 'submitted to board, waiting for acceptance' if self.board_state == 'submit'
    return 'rejected by project board' if self.board_state == 're_prep'
    return 'project board approved, requesting data' if self.board_state == 'accept'
    return 'data request rejected' if self.board_state == "data_rejected"
    return 'final' if self.board_state == 'final' && !self.expiry_date.blank?
    return 'download rights expired' if self.board_state == 'final' && self.expiry_date.blank?
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

    pp_hash['pp_year'] = self.created_at.year.blank? ? "" : "#{self.created_at.year}, "
    pp_hash['pp_title'] = self.title.blank? ? "" : "#{self.title}, "
    pp_hash['pp_journal'] = self.envisaged_journal.blank? ? "" : ", <i>Citation</i>: #{envisaged_journal}".html_safe

    proponents_and_dataowners_array = []
    self.authors_selection(:proponents_and_all_owners).each do |p|
      proponents_and_dataowners_array << p.firstname + " " + p.lastname
    end

    proponents_and_dataowners_array = proponents_and_dataowners_array.sort
    pp_hash['pp_proponents_and_dataowners'] = proponents_and_dataowners_array.blank? ? "" : "<i>Proponents and dataowners</i>: #{proponents_and_dataowners_array.split.join(", ")}".html_safe

    "#{ pp_hash["pp_project_short_name"]} #{pp_hash["pp_author"]} #{pp_hash["pp_year"]} #{pp_hash["pp_title"]} #{pp_hash["pp_proponents_and_dataowners"]} #{pp_hash["pp_journal"]}".html_safe
  end

  def self.get_all_pp_years
    years = []
    self.all.each do |pp|
      years << pp.created_at.year
    end
    return years.uniq
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

  def current_votes
    case self.board_state
      when 're_prep', 'submit'
        {:type => :project_board, :votes => self.project_board_votes}
      when 'accept', 'data_rejected'
        {:type => :data_requests, :votes => self.for_data_request_votes}
      else
        {:type => :none, :votes => []}
    end
  end

  def update_proponents proponents_array
    proponents = User.find_all_by_id(proponents_array).map{|person| AuthorPaperproposal.new(:user => person, :kind => "user")}
    AuthorPaperproposal.delete_all(['paperproposal_id = ? AND kind = ?', self.id, 'user'])
    self.author_paperproposals << proponents
  end

  def update_datasets(dataset_ids, aspects)
    old_datasets = self.datasets.to_a

    if self.board_state == 'final'
      self.board_state = 'accept'
      download_rights_message = reset_download_rights
    end

    self.update_attributes(:dataset_ids => dataset_ids)
    if aspects
      aspects.each do |k, v|
        ds_pp = self.dataset_paperproposals.where('dataset_id = ?', k).first
        ds_pp.aspect = v
        ds_pp.save
      end
    end

    self.reload
    calculate_datasets_proponents

    if %w'prep re_prep submit'.include?(self.board_state)
      set_lock_status
      self.save
    else
      calculate_votes old_datasets
      finalize_votes_and_lock
    end
    download_rights_message || ''
  end

  def calculate_votes(old_datasets_array = [])
    return if %w'prep re_prep submit'.include? self.board_state # there are not data votes right now

    old_data_voters = self.for_data_request_votes.collect{|pv| pv.user}
    new_data_voters = self.datasets.collect{|ds| ds.owners}.flatten.uniq
    removed_voters = old_data_voters - new_data_voters
    added_voters = new_data_voters - old_data_voters

    all_referred_datasets = (old_datasets_array + self.datasets).uniq
    unchanged_datasets = old_datasets_array & self.datasets
    changed_datasets = all_referred_datasets - unchanged_datasets
    changed_datasets_owners = changed_datasets.collect{|ds| ds.owners}.flatten.uniq

    # add, reset and delete votes
    changed_datasets_owners.each do |u|
      if removed_voters.include? u
        self.for_data_request_votes.where(:user_id => u.id).first.destroy
      elsif added_voters.include? u
        self.paperproposal_votes << PaperproposalVote.new(:user => u, :project_board_vote => false)
      else
        vote = self.for_data_request_votes.where(:user_id => u.id).first
        vote.update_attribute(:vote,'none') if vote.vote == 'accept'
      end
    end
  end

  def user_changes_state
    if %w'prep re_prep'.include?(self.board_state)
      submit_to_board
    elsif self.board_state == 'data_rejected'
      re_request_data
    elsif self.board_state == 'final'
      hard_reset
    else
      'Paperproposal state could not be changed'
    end
  end

  def check_votes
    self.reload
    if self.paperproposal_votes.where(:vote => 'accept').count == self.paperproposal_votes.count
      all_votes_accepted
    elsif !self.paperproposal_votes.where(:vote => 'reject').empty?
      reject_data_request
    end
  end

  def hard_reset
    result = ''
    result = reset_download_rights if self.board_state == 'final'
    result << "#{self.paperproposal_votes.count} votes deleted."
    self.paperproposal_votes.delete_all

    self.board_state = 'prep'
    finalize_votes_and_lock
    result
  end

  def safe_delete(user)
    if self.board_state == 'prep' || user.has_role?(:admin) || user.has_role?(:data_admin)
      self.destroy
      'Paperproposal was destroyed'
    else
      self.update_attribute :state, 'deletion'
      'Paperproposal flagged for deletion by an admin'
    end
  end

  def reset_download_rights
    return 'paperproposal is not final' unless self.board_state == 'final'

    self.update_attribute(:expiry_date, '')
    other_final_paperproposals = Paperproposal.where("board_state = 'final' AND author_id = ? AND id != ?", self.author_id, self.id)
    other_downloadable_datasets = other_final_paperproposals.collect{|pp| pp.datasets}.flatten.uniq
    unique_downloadable_datasets = (self.datasets - other_downloadable_datasets)

    reverted_roles = []
    unique_downloadable_datasets.each do |ds|
      self.author.has_no_role! :proposer, ds
      reverted_roles << ds.id
    end
    "Reverted proposer roles for datasets #{reverted_roles.to_s}. "
  end

  def self.revoke_old_download_rights
    expired = Paperproposal.where('expiry_date < ?', Date.today.to_s)
    expired.each do |pp|
      puts Time.now.to_s + ' Paperproposal ' + pp.id.to_s + ': ' + pp.reset_download_rights
    end
  end

private

  def submit_to_board
    pre_state = self.board_state
    self.board_state = 'submit'

    if pre_state == 're_prep'
      self.project_board_votes.each{|vote| vote.update_attribute(:vote, 'none')}
    else
      Role.find_by_name('project_board').users.each do |user|
        self.paperproposal_votes << PaperproposalVote.new(:user => user, :project_board_vote => true)
      end
    end

    finalize_votes_and_lock
    'Submitted to project board'
  end

  def re_request_data
    self.board_state = 'accept'

    self.for_data_request_votes.where(:vote => 'reject').each do |v|
      v.update_attribute :vote, 'none'
    end

    finalize_votes_and_lock
    'Requesting data again'
  end

  def all_votes_accepted
    case self.board_state
      when 'submit'
        if self.datasets.length == 0
          make_data_request_final
        else
          make_data_request_accepted
        end
      when 'accept'
        make_data_request_final
      else
    end
  end

  def reject_data_request
    self.board_state = case self.board_state
                         when 'submit' then 're_prep'
                         when 'accept' then 'data_rejected'
                         else self.board_state
                       end
    NotificationMailer.delay.data_request_rejected(self)
    set_lock_status
    self.save
  end

  def make_data_request_accepted
    self.board_state = 'accept'
    calculate_votes
    finalize_votes_and_lock
  end

  def make_data_request_final
    self.expiry_date = Date.today + 2.years
    self.board_state = 'final'
    self.datasets.each do |ds|
      ds.accepts_role! :proposer, self.author
    end
    set_lock_status
    self.save
  end

  def auto_vote
    auto_voters = []

    case self.board_state
      when 'accept'
        # search data owners who only contribute free (in general + for members) datasets
        auto_voters = self.main_aspect_dataset_owners + self.side_aspect_dataset_owners
        auto_voters.delete self.author
        self.datasets.each do |ds|
          unless ds.free_for_members || ds.free_for_public
            auto_voters = auto_voters - ds.owners
          end
        end
        auto_voters << self.author # add paperproposal author

        # accept data request votes
        auto_voters.uniq!
        self.for_data_request_votes.where('user_id IN (?)', auto_voters).each do |v|
          unless v.vote == 'accept'
            v.update_attribute(:vote, 'accept')
            NotificationMailer.delay.auto_accept_for_free_datasets(v.user, self) unless v.user == self.author
          end
        end
      when 'submit'
        self.project_board_votes.where(:user_id => self.author).each do |v|
          v.update_attribute(:vote, 'accept') unless v.vote == 'accept'
        end
    end
  end

  def set_lock_status
    self.lock = %w'prep re_prep data_rejected final'.include?(self.board_state) ? false : true
  end

  def finalize_votes_and_lock
    set_lock_status
    self.save
    auto_vote
    check_votes
  end

  def check_aspects_for_contexts
    if self.datasets.length >= 0
      self.dataset_paperproposals.each do |dgdr|
        return false if dgdr.blank?
      end
      return true
    end
    return false
  end

end
