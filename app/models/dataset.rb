## This file contains the Dataset model, which maps the database table Datasets for the application. The Dataset title must be unique.
##
## Datasets contain the general metadata of a dataset. In addition, a dataset can contain:
## 1. Primary research data, as uploaded data values from a "Dataworkbook", where the measurement information is stored in the "Datacolumn"
## and the data values in "Sheetcell"s. The original "Dataworkbook" is stored as a "Datafile" which is referenced by the Dataset, in the "upload_spreadsheet_id" field.
## 2. one or more asset ("Freeformat") files.
##
## Datasets are taggable, that is, they can be linked to entries in the Tags table. This uses the is_taggable
## rails gem.
##
## Dataset provenance is managed using the ACL9 rails gem. "User"s can be given different roles in relation to a Dataset
## and access to the Dataset is controlled via the "Role".
##
## Datasets can belong to one or more "Project"s. They are linked through the "DatasetProject" class.
##
## "Paperproposal"s contain one or more Datasets. They are linked through the "DatasetPaperProposal" class.
##
## Highlighted methods:
## 1. "approve_predefined_columns": after the initial upload of data a user can bulk approve columns, without reviewing each
## column individually. The Datacolumn must be corrected described, in that it must have a datagroup and a datatype.

class Dataset < ActiveRecord::Base

  acts_as_authorization_object :subject_class_name => 'User'

  is_taggable :projecttags   # deprecated #TODO this is used in the download action -> but marked as deprecated
  is_taggable :tags, :languages

  belongs_to :upload_spreadsheet, :class_name => "Datafile",
                                  :foreign_key => "upload_spreadsheet_id",
                                  :dependent => :destroy

  has_many :datacolumns, :dependent => :destroy, :order => "columnnr"
  has_many :sheetcells, :through => :datacolumns

  has_many :freeformats, :as => :freeformattable, :dependent => :destroy

  #has_many :dataset_projects
  #has_many :projects, :through => :dataset_projects
  has_and_belongs_to_many :projects

  with_options :unless => "new_record?" do |x|
    x.validates_presence_of :title
    x.validates_uniqueness_of :title
  end

  validates_uniqueness_of :filename, :allow_blank => true
  validates_associated :upload_spreadsheet

  before_validation(:load_metadata_from_spreadsheet, :on => :create)
  before_destroy :delete_sheetcells
  before_save :add_xls_extension_to_filename

  def add_xls_extension_to_filename
    if self.filename
      /\.xls$/.match(self.filename) ? self.filename : self.filename = "#{self.filename}.xls"
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
    self.abstract + " " + f_strings.join(" --- ")
  end

  def set_start_and_end_dates_of_research(book)
    self.datemin = book.datemin
    self.datemax = book.datemax
  end

  def cells_linked_to_values?
    sheetcells = self.sheetcells.all(:conditions => ["accepted_value IS NOT NULL OR accepted_value !='' OR category_id > 0"])
    !sheetcells.empty?
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


  def delete_sheetcells
    datacolumns.each do |column|
      column.sheetcells.delete_all
    end
  end

  def delete_imported_research_data_and_file
    delete_sheetcells
    datacolumns.destroy_all
    upload_spreadsheet.try(:destroy)
  end

  def owners
    self.users.select{|u| u.has_role?(:owner, self)}
  end

  def export_to_excel_as_stream
    ExcelExport.new(self).data_buffer
  end

  def increment_download_counter
    self.downloads = (self.downloads || 0) + 1
    save
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
    dates += self.datacolumns.collect {|x| x.updated_at}
    dates.max
  end

end
