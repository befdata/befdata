# This file contains the Dataset model, which maps the database table Datasets for the application.
# The Dataset title must be unique.

# Datasets contain the general metadata of a dataset. In addition, a dataset can contain:
# 1. Primary research data, as uploaded data values from a Dataworkbook,
#    where the information on the column is stored in Datacolumn instances
#    and the data values in Sheetcell instances. The original dataworkbook is stored as a Datafile
#    which is referenced by the dataset, in the upload_spreadsheet_id field.
# 2. one or more asset (Freeformat) files.
#
# Datasets are taggable, that is, they can be linked to entries in the Tags table. This uses the is_taggable
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

class Dataset < ActiveRecord::Base

  acts_as_authorization_object :subject_class_name => 'User'

  acts_as_taggable


  has_attached_file :generated_spreadsheet,
    :path => ":rails_root/files/:id_generated-download.xls"

  belongs_to :upload_spreadsheet, :class_name => "Datafile",
    :foreign_key => "upload_spreadsheet_id",
    :dependent => :destroy

  has_many :datacolumns, :dependent => :destroy, :order => "columnnr"
  has_many :sheetcells, :through => :datacolumns
  has_many :datagroups, :through => :datacolumns, :include => :categories
  has_many :freeformats, :as => :freeformattable, :dependent => :destroy

  has_many :dataset_downloads

  has_and_belongs_to_many :projects
  has_many :dataset_paperproposals
  has_many :paperproposals, :through => :dataset_paperproposals

  validates :title, :presence => true, :uniqueness => true

  validates_associated :upload_spreadsheet, :if => "upload_spreadsheet_id_changed?"

  before_validation(:load_metadata_from_spreadsheet, :on => :create)

  before_save :add_xls_extension_to_filename

  before_destroy :check_for_paperproposals

  def add_xls_extension_to_filename
    if self.filename
      /\.xls$/.match(self.filename) ? self.filename : self.filename = "#{self.filename}.xls"
    end
  end

  def check_for_paperproposals
    if paperproposals.count > 0
      errors.add(:dataset,
        "can not be deleted while linked paperproposals exist [ids: #{paperproposals.map{|pp| pp.id}.join(", ")}]")
      return false
    end
  end

  def load_metadata_from_spreadsheet
    return if upload_spreadsheet.nil?

    book = dataworkbook
    self.attributes = book.general_metadata_hash
    self.set_start_and_end_dates_of_research(book)
    try_retrieving_projects_from_tag_list(book)
  end

  def try_retrieving_projects_from_tag_list(book)
    return if book.tag_list.blank?
    book.tag_list.split(",").each do |t|
      Project.find_by_converting_to_tag(t).each do |p|
        self.projects << p unless self.projects.include? p
      end
    end
  end

  def has_research_data?
    !upload_spreadsheet.blank?
  end

  def dataworkbook
    Dataworkbook.new(upload_spreadsheet)
  end

  def abstract_with_freeformats
    f_strings = self.freeformats.collect do |f|
      "File asset " + f.file_file_name + (f.description.blank? ? "" : (": " + f.description))
    end
    self.abstract + (f_strings.empty? ? "" : (" - " + f_strings.join(" - ")))
  end

  def set_start_and_end_dates_of_research(book)
    self.datemin = book.datemin
    self.datemax = book.datemax
  end

  def cells_linked_to_values?
    self.sheetcells.exists?(["accepted_value IS NOT NULL OR accepted_value !='' OR category_id > 0"])
  end

  # During the import routine, we step through each of the data
  # columns using their header.
  def headers
    self.datacolumns.collect{|dc| dc.columnheader}
  end

  def finished_datacolumns
    datacolumns.select{|dc| dc.finished == true}
  end

  def datacolumns_with_approved_datagroup
    datacolumns.select{|dc| dc.datagroup_approved == true}
  end

  def datacolumns_with_approved_datatype
    datacolumns.select{|dc| dc.datatype_approved == true}
  end

  def predefined_columns
    # To be predefined, a column must have a datagroup and a datatype that is not 'unknown'.
    # The datagroup is created at import, so we only have to check for the datatype.
    # Furthermore, the datacolumn approval process must not have already started.
    datacolumns.select{|dc| Datatypehelper.find_by_name(dc.import_data_type).name != 'unknown' && dc.untouched?}
  end

  def approve_predefined_columns(approving_user)
    @columns_with_invalid_values = []
    predefined_columns.each do |column|
      column.datagroup_approved = true

      # Approve the datatype and store the values
      column.add_data_values(approving_user)
      column.datatype_approved = true

      # Check for invalid values
      column.finished = true if column.invalid_values.blank?
      @columns_with_invalid_values << column unless column.invalid_values.blank?

      # Save the column
      column.save
    end

  end

  def columns_with_invalid_values_after_approving_predefined
    #TODO this should be a proper method without relying on the state of this object
    raise "This method may be only called directly after executing 'approve_predefined_columns'" unless @columns_with_invalid_values
    @columns_with_invalid_values
  end

  def delete_imported_research_data_and_file
    datacolumns.destroy_all
    upload_spreadsheet.try(:destroy)
  end

  def owners
    self.users.select{|u| u.has_role?(:owner, self)}
  end

  def log_download(downloading_user)
    # increment the download counter
    # temporarily turn off timestamp update otherwise the update date is updated everytime someone downloads the dataset
    class << self
      def record_timestamps; false; end
    end
    self.downloads = (self.downloads || 0) + 1
    save
    # turn on the timestamp update
    class << self
      def record_timestamps; true; end
    end

    # log the download
    DatasetDownload.create(:user => downloading_user,
                          :dataset => self)
  end

  def number_of_observations
    #TODO use sql query finding max rownumber
    return 0 if datacolumns.empty?
    return datacolumns.first.sheetcells.count
  end

  def last_update
    dates = Array.new
      dates << self.updated_at
    dates << self.upload_spreadsheet.updated_at unless self.upload_spreadsheet.nil?
    dates += self.freeformats.collect {|x| x.updated_at}
    dates.max
  end

  def import_data
    begin
      self.update_attribute(:import_status, 'started importing')
      book = Dataworkbook.new(upload_spreadsheet)
      book.import_data
      self.update_attribute(:import_status, 'finished')
      self.enqueue_to_generate_download(:high)
    rescue Exception => e
      Rails.logger.error e.message
      Rails.logger.error e.backtrace.join("\n")
      self.update_attribute(:import_status, "error: #{e.message}")
    end
  end

  def finished_import?
    self.import_status.to_s == 'finished' || !self.has_research_data?
  end

  def enqueue_to_generate_download(priority = :low)
    priority = 10 if priority.eql?(:low)
    priority = 0 if priority.eql?(:high)
    self.reload
    return unless finished_import?
    return if download_generation_status.eql?('queued')
    self.update_attribute(:download_generation_status, 'queued')
    self.delay(:priority => priority).generate_download
  end

  def generate_download
    self.update_attribute(:download_generation_status, 'started')

    self.generated_spreadsheet = ExcelExport.new(self).excel_temp_file
    self.generated_spreadsheet_file_name = title.gsub(/[^\w]/, '-')
    self.generated_spreadsheet_content_type = "application/xls"
    self.download_generated_at = Time.now + 1.second
    self.download_generation_status = 'finished'
    puts "=== Download generated for Dataset id: #{id} at #{Time.now}"
    save
  end

  def approval_finished?
    !self.datacolumns.any?{|dc| dc.approval_stage!="4"}
  end


  def refresh_paperproposal_authors
    self.paperproposals.each {|pp| pp.calculate_datasets_proponents}
  end

  def to_csv (seperate_category_columns = false)
    # gather columns and values
    all_columns = []
    self.datacolumns.order("columnnr ASC").each do |dc|
      column = []
      category_column = []
      column[0] = dc.columnheader
      category_column[0] = "#{dc.columnheader} - Categories"

      dc.sheetcells.each do |sc|
        if !seperate_category_columns || dc.import_data_type == 'category' || !(sc.datatype && sc.datatype.is_category? && sc.category)
          column[sc.row_number - 1] = sc.export_value
        else
          category_column[sc.row_number - 1] = sc.export_value
        end
      end
      all_columns << column
      all_columns << category_column if category_column.length > 1
    end

    # bring to same length to transpose
    max_length = all_columns.map{|c| c.length}.max
    all_columns.each{|c|   c[max_length-1] = nil unless c.length == max_length}
    all_columns  = all_columns.transpose

    CSV.generate do |csv|
      all_columns.each {|c| csv << c}
    end
  end

  def all_tags
    (tags + self.datacolumns.map(&:tags)).flatten.uniq
  end
end
