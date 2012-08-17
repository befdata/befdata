class Paperproposal < ActiveRecord::Base

  # acts_as_authorization_object :subject_class_name => 'Project'

  belongs_to :author, :class_name => "User", :foreign_key => "author_id"
  belongs_to :corresponding, :class_name => "User", :foreign_key => "corresponding_id"
  belongs_to :senior_author, :class_name => "User", :foreign_key => "senior_author_id"

  belongs_to :authored_by_project, :class_name => "Project", :foreign_key => :project_id

  has_many :authors, :class_name => "User", :source => :user, :through => :author_paperproposals
  has_many :author_paperproposals, :dependent => :destroy, :include => [:user]

  has_many :coordinators, :class_name => "User", :source => :person, :through => :paperproposal_votes,
           :conditions => ['project_board_vote = ?',true]

  has_many :project_board_votes, :class_name => "PaperproposalVote",
           :source => :paperproposal_votes, :conditions => {:project_board_vote => true }

  has_many :for_data_request_votes, :class_name => "PaperproposalVote",
           :source => :paperproposal_votes, :conditions => {:project_board_vote => false }

  has_many :paperproposal_votes, :dependent => :destroy

  has_many :dataset_paperproposals, :dependent => :destroy
  has_many :datasets, :through => :dataset_paperproposals

  has_many :freeformats, :as => :freeformattable, :dependent => :destroy

  accepts_nested_attributes_for :authors

  validates_presence_of :title, :rationale

#    def delete_all_data_groups_except(data_groups)
#      self.data_group_data_requests.each do |data_group_data_request|
#        next if data_groups.include?(data_group_data_request.measurements_methodstep)
#        data_group_data_request.delete
#      end
#    end

  STATES = {
    # for the sorting
    'accepted' => 1,
    'in review' => 2,
    'manuscript avaible' => 3,
    'in prep' => 4
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

  def author_list
    middle_block = self.author_paperproposals.reject{|e| e.kind == "ack"}.map{|e| e.user}.uniq
    middle_block << self.corresponding
    middle_block.reject!{|e| e == self.senior_author || e == self.author}
    middle_block.uniq!
    middle_block.sort!{|a,b| a.lastname <=> b.lastname}

    author_list = [self.author, middle_block, self.senior_author]
    author_list.flatten!
    author_list.uniq!

    ack = self.author_paperproposals.select{|e| e.kind == "ack"}.map{|e| e.user}.uniq
    ack.reject!{|e| author_list.include?(e) }
    ack = ack.sort{|a,b| a.lastname <=> b.lastname}

    {:author_list => author_list, :corresponding => self.corresponding, :ack => ack}
  end

  def calc_authorship(user)
     if(self.author_id==user.id)
       "Author"
     else
       if(self.corresponding_id==user.id)
         "Corresponding author"
       else
         if(self.senior_author_id===user.id)
           "Senior author"
         end
       end
     end
  end

  def beautiful_title (only_authors = false)
    # gives back a nice string to display, like: Kraft, N. J., Comita, L. S. (2011): DisentanglingAlong Latitudinal and Elevational Gradients. Science, 333(6050).
    authors = self.author_list[:author_list].collect{|a| a.short_name}.join(", ")
    return authors if only_authors

    year = self.state != 'accepted' ? "" : " (#{self.envisaged_date.year})"
    publication = self.envisaged_journal.blank? ? "" : " #{envisaged_journal}."
    "#{authors} (Portal members involved)#{year}: #{self.title}. #{publication}"
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
