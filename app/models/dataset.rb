# This file contains the Dataset model, which maps the database table Datasets for the application.
# The Dataset title must be unique.

# Datasets contain the general metadata of a dataset. In addition, a dataset can contain:
# 1. Primary research data, as uploaded data values from a Workbook or CSV
#    where the information on the column is stored in Datacolumn instances
#    and the data values in Sheetcell instances. The original Workbook is stored as a Datafile
# 2. one or more asset (Freeformat) files.
#
# Datasets are taggable, that is, they can be linked to entries in the Tags table. This uses the Acts_as_taggable
# rails gem.
#
# Dataset provenance is managed using the ACL9 rails gem. Users can be given different roles in relation
# to a dataset (see User) and access to the dataset is controlled via the Role.
#
# Datasets can belong to one or more Project instances. They can also set free for download within their
# projects.
#
# Paperproposal instances contain one or more datasets. They are linked through
# the DatasetPaperproposal class.
#
# Highlighted methods:
# * approve_predefined_columns : after the initial upload of data a User can bulk approve columns,
#   without reviewing each column individually. The Datacolumn must be correctly described, in
#   that it must have a Datagroup and a Datatype.
require 'acl_patch'
require 'elasticsearch/model'
class Dataset < ActiveRecord::Base
  acts_as_authorization_object :subject_class_name => 'User', join_table_name: 'roles_users'
  include AclPatch
  include Elasticsearch::Model

  attr_writer :owner_ids
  acts_as_taggable

  has_many :datafiles, :class_name => "Datafile", :order => 'id DESC', :dependent => :destroy
  has_one  :current_datafile,  :class_name => "Datafile", :order => 'id DESC'

  has_many :exported_files, :dependent => :destroy
  has_one  :exported_excel   # exported Excel workbook
  has_one  :exported_csv     # exported regular csv
  has_one  :exported_scc_csv # exported csv with separate coategory columns

  has_many :datacolumns, :dependent => :destroy, :order => "columnnr"
  has_many :sheetcells, :through => :datacolumns
  has_many :datagroups, :through => :datacolumns, :include => :categories
  has_many :freeformats, :as => :freeformattable, :dependent => :destroy

  has_many :dataset_downloads
  has_many :downloaders, :through => :dataset_downloads, :source => :user, :uniq => true

  has_many :dataset_edits, :order => 'updated_at DESC', :dependent => :destroy
  has_one :unsubmitted_edit, :class_name => 'DatasetEdit', :conditions => ['submitted=?',false]

  has_and_belongs_to_many :projects
  has_many :dataset_paperproposals
  has_many :paperproposals, :through => :dataset_paperproposals
  has_many :proposers, :through => :paperproposals, :source => :author, :uniq => true

  has_many :dataset_tags
  has_many :all_tags, :through => :dataset_tags, :source => :tag, :order => 'lower(name)'

  validates :title, :presence => true, :uniqueness => { case_sensitive: false }

  ACCESS_CODES = {
    private: 0,
    free_within_projects: 1,
    free_for_members: 2,
    free_for_public: 3
  }
  validates_inclusion_of :access_code, :in => ACCESS_CODES.values,
                         :message => 'is invalid! Access Rights is out of Range.'

  before_destroy :check_for_paperproposals
  before_save :set_include_license, :check_author

  index_name [Rails.application.class.parent_name.underscore, File.basename(Rails.root), Rails.env].join('_')


  IndexSettings = {
    number_of_shards: 1,
    analysis: {
      analyzer: {
        default: {
          type: 'snowball'
        }
      }
    }
  }

  settings index: IndexSettings do
    mapping dynamic: false do
      indexes :title,                type: 'multi_field' do
        indexes :title,              analyzer: 'snowball', boost: 10
        indexes :simple,             analyzer: 'simple'
      end

      # metadata
      indexes :abstract,             type: :string
      indexes :design,               type: :string
      indexes :spatialextent,        type: :string
      indexes :temporalextent,       type: :string
      indexes :taxonomicextent,      type: :string
      indexes :circumstances,        type: :string
      indexes :dataanalysis,         type: :string

      # datacolumn meta
      indexes :datacolumns, type: 'nested' do
        indexes :columnheader,       type: :string, boost: 5
        indexes :definition,         type: :string
        indexes :informationsource,  type: :string
        indexes :instrumentation,    type: :string
        indexes :datagroup_title,    type: :string, boost: 2
        indexes :datagroup_description, type: :string
      end

      indexes :owners, type: 'multi_field' do
        indexes :owners,             analyzer: 'keyword',  boost: 2
        indexes :tokenized,          analyzer: 'snowball', boost: 2
      end

      indexes :tags,                 type: 'multi_field' do
        indexes :tags,               analyzer: 'keyword',  boost: 3
        indexes :tokenized,          analyzer: 'snowball',  boost: 3
      end

      indexes :datagroups,           type: :string, analyzer: 'keyword', include_in_all: false

      indexes :projects,             type: :string, analyzer: 'keyword', include_in_all: false

      indexes :access_code,          type: :integer, include_in_all: false

      indexes :has_freeformats,      type: :boolean
      indexes :has_datafiles,        type: :boolean

      indexes :updated_at,           type: :date, include_in_all: false
    end
  end

  def self.index(*args) # elasticsearch's import method collides with activerecord-import'
    self.__elasticsearch__.import(*args)
  end

  def as_indexed_json(options={})
    hash = self.as_json(
      only: [:title, :abstract, :design, :spatialextent, :temporalextent, :taxonomicextent, :circumstances, :dataanalysis, :access_code, :updated_at],
      include: {
        datacolumns: {
          only: [:columnheader, :definition, :informationsource, :instrumentation],
          methods: [:datagroup_title, :datagroup_description]
        }
      }
    )

    hash['owners'] = self.owners.map(&:full_name)
    hash['tags'] = self.all_tags.pluck(:name)

    hash['datagroups']      = self.datagroups.pluck(:title)
    hash['projects']        = self.projects.pluck(:shortname)
    hash['has_freeformats'] = self.freeformats_count > 0
    hash['has_datafiles']   = self.datafiles_count > 0
    hash
  end

  def self.search(q, options = {})
    search_definition = {
      query: {}
    }

    if q.blank?
      search_definition[:query] = {match_all: {}}
    else
      search_definition[:query] = {
        query_string: {query: q.strip, default_operator: 'AND', analyzer: 'snowball'}
      }
    end

    self.__elasticsearch__.search search_definition
  end


  def load_projects_and_authors_from_current_datafile
    return unless current_datafile
    current_datafile.authors_list[:found_users].each {|user| user.has_role!(:owner, self) }
    self.projects = current_datafile.projects_list if current_datafile.projects_list.present?
  end

  def add_datafile(datafile)
    datafile.update_attributes(dataset: self)
    self.update_attributes(filename: datafile.basename, import_status: 'new')
  end

  def has_research_data?
    datafiles_count && datafiles_count > 0
  end

  def access_rights
    (ACCESS_CODES.invert)[access_code].to_s.humanize
  end

  %w{free_within_projects free_for_members free_for_public}.each do |right|
    define_method("#{right}?") do
      access_code >= ACCESS_CODES[right.to_sym]
    end
  end

  def abstract_with_freeformats
    f_strings = self.freeformats.collect do |f|
      "File asset " + f.file_file_name + (f.description.blank? ? "" : (": " + f.description))
    end
    self.abstract.to_s + (f_strings.empty? ? "" : (" - " + f_strings.join(" - ")))
  end

  def cells_linked_to_values?
    self.sheetcells.exists?(["accepted_value IS NOT NULL OR accepted_value !='' OR category_id > 0"])
  end

  def headers
    self.datacolumns.pluck(:columnheader)
  end

  def predefined_columns
    datacolumns.select{|dc| dc.predefined? }
  end

  def approve_predefined_columns
    @columns_with_invalid_values = []
    predefined_columns.each do |column|
      column.datagroup_approved = true

      # Approve the datatype and store the values
      column.add_data_values
      column.datatype_approved = true

      # Check for invalid values
      column.finished = true if !column.has_invalid_values?
      @columns_with_invalid_values << column if column.has_invalid_values?

      # Save the column
      column.save
    end
  end

  def columns_with_invalid_values_after_approving_predefined
    #TODO this should be a proper method without relying on the state of this object
    raise "This method may be only called directly after executing 'approve_predefined_columns'" unless @columns_with_invalid_values
    @columns_with_invalid_values
  end

  def delete_imported_research_data
    datacolumns.destroy_all
    self.exported_files.destroy_all
  end

  def log_download(downloading_user)
    DatasetDownload.create(:user => downloading_user, :dataset => self)
  end

  def number_of_observations
    #TODO use sql query finding max rownumber
    return 0 if datacolumns.empty?
    return datacolumns.first.sheetcells.count
  end

  def import_data
    begin
      self.update_attribute(:import_status, 'started importing')
      current_datafile.import_data
      self.update_attribute(:import_status, 'finished')
      ExportedFile.initialize_export(self)
    rescue Exception => e
      Rails.logger.error e.message
      Rails.logger.error e.backtrace.join("\n")
      self.update_attribute(:import_status, "error: #{e.message.first(248)}")
    end
  end

  def finished_import?
    self.import_status.to_s == 'finished' || !self.has_research_data?
  end

  def being_imported?   # TODO: this is prone to be out of sync if new status added
    return false unless self.has_research_data?
    %w{new finished}.exclude?(import_status) && !import_status.start_with?('error')
  end

  def refresh_paperproposal_authors
    self.paperproposals.each {|pp| pp.update_datasets_providers}
  end

  # This method returns similar datasets which share keywords with current dataset.
  # datasets are sorted by similarity in descending order
  def find_related_datasets
    tags = self.all_tags.pluck(:id)
    return [] if tags.empty?
    datasets = Dataset.joins(:dataset_tags)
                      .select("datasets.*")
                      .where(["tag_id in (?) and datasets.id <> ?", tags, self.id])
                      .group("datasets.id").order("count(tag_id) desc")
    return(datasets)
  end

  # acl9 role related staff: different kinds of user
  def owners
    get_user_with_role(:owner)
  end

  def owner_ids
    owners.map(&:id)
  end

  def owners= (people)
    set_user_with_role(:owner, people)
  end

  # keep log of edits
  def create_or_use_unsubmitted_edit
    if !self.unsubmitted_edit.nil?
      self.unsubmitted_edit
    else
      self.dataset_edits.new
    end
  end

  def log_edit(string)
    unless self.unsubmitted_edit.nil? && (Time.now - 10.minutes) < self.created_at
      self.create_or_use_unsubmitted_edit.add_line!(string)
    end
  end

  def free_for?(user)
    return true if self.free_for_public?
    return false unless user
    return true if self.free_for_members?
    return true if self.free_within_projects? && !(user.projects & self.projects).empty?
    false
  end

  def can_download_by?(user)
    return false unless self.current_datafile
    return true if self.free_for?(user)
    return false unless user
    return true if user.has_role?(:proposer, self) || user.has_role?(:owner, self)
    return true if user.has_role?(:admin) || user.has_role?(:data_admin)
    false
  end

  def can_edit_by?(user)
    return false unless user
    return true if user.has_role?(:owner, self) || user.has_role?(:admin) || user.has_role?(:data_admin)
    false
  end

private

  def check_for_paperproposals
    if paperproposals.count > 0
      errors.add(:dataset,
                 "can not be deleted while linked paperproposals exist [ids: #{paperproposals.map{|pp| pp.id}.join(", ")}]")
      return false
    end
  end

  def set_include_license
    self.include_license = false unless self.free_for_public?
    return true
  end

  def check_author
    if @owner_ids
      @owner_ids.reject!(&:blank?)
      if @owner_ids.empty?
        self.errors.add :base, 'The dataset should have at least one author.'
        return false
      else
        self.owners = User.find(@owner_ids)
      end
    end
  end
end
