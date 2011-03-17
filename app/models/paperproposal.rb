class Paperproposal < ActiveRecord::Base

    belongs_to :author, :class_name => "User", :foreign_key => "author_id"
    belongs_to :corresponding, :class_name => "User", :foreign_key => "corresponding_id"
    belongs_to :senior_author, :class_name => "User", :foreign_key => "senior_author_id"

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
    has_many :filevalues, :dependent => :destroy

    accepts_nested_attributes_for :filevalues, :allow_destroy => true
    accepts_nested_attributes_for :authors

    validates_presence_of :title, :rationale

#    def delete_all_data_groups_except(data_groups)
#      self.data_group_data_requests.each do |data_group_data_request|
#        next if data_groups.include?(data_group_data_request.measurements_methodstep)
#        data_group_data_request.delete
#      end
#    end

    def calc_board_state
      return "In Preparation, no data selected yet." if self.board_state == "prep" && self.contexts.length == 0
      return "still no aspects set" if self.board_state == "prep" && !check_aspects_for_contexts
      return "complete" if self.board_state == "prep" && check_aspects_for_contexts
      return "Submitted to board, waiting for acceptance." if self.board_state == "submit"
      return "Project Board rejected your data request. Please make changes and submit again." if self.board_state == "re_prep"
      return "accept" if self.board_state == "accept"
      return "final" if self.board_state == "final"
    end

    def author_list
      author_list = []
      author_list << self.author

      middle_block = self.author_data_requests.reject{|e| e.kind == "ack"}.map{|e| e.person}.uniq
      ack = self.author_data_requests.select{|e| e.kind == "ack"}.map{|e| e.person}.uniq
      middle_block << self.corresponding

      middle_block = middle_block.sort{|a,b| a.lastname <=> b.lastname}
      middle_block.reject!{|e| e == self.senior_author}
      middle_block.reject!{|e| e == self.author}
      middle_block.each{|e| author_list << e}

      author_list << self.senior_author

      ack.reject!{|e| middle_block.include?(e) ||
                      e == self.senior_author ||
                      e == self.author}

      ack = ack.sort{|a,b| a.lastname <=> b.lastname}

      hash = {:author_list => author_list, :corresponding => self.corresponding, :ack => ack}
      logger.inspect
      return hash
    end

    private

    def check_aspects_for_contexts
      if self.contexts.length >= 0
        self.data_request_contexts.each do |dgdr|
          if dgdr.aspect.nil? || dgdr.aspect.empty?
            return false
          end
        end
        return true
      end
      return false
    end


end
