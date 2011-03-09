


# Filevalues manage files.  They don't contain the file itself, but
# they point at files located in the /public/files directory.  Files
# are of two types: they can be a raw data spreadsheet, which is
# uploaded in all it's cells and stored in single Measurement
# instances.  They can also be free format files, that are associated
# with Context instances.  !! this link table has still to be done, it
# may also be added as column to the filevalues table, since every
# file should be within one context.  Then we should also indicate, if
# this is a BEF spreadsheet or if it is a free format file.
class Filevalue < ActiveRecord::Base

  has_many :measurements, :as => :value
  has_one :context, :foreign_key => :upload_spreadsheet_id
#! we probably also need a context upload big data file for logger
#! files


  validates_uniqueness_of :file_file_name

  has_attached_file :file,
  :basename => "basename",
  :path => ":rails_root/public/files/:filename", 
  :url => "#{MY_CONFIG["root_url"]}/files/:id/download"

  # tagging
  is_taggable :tags, :languages

#  before_destroy :check_for_measurements
#
# measurements will not be linked to filevalues, there will be a
# separate table for uploading free format files

  after_destroy :destroy_taggings

#  def check_for_measurements
#    puts "in check for measurements"
#    unless self.measurements.length == 0
#      puts "data cells linked"
#      errors.add_to_base "Cannot destroy value with Data Cells associations"
#      false
#    end
#  end

  def basename
    return File.basename(self.file.original_filename, File.extname(self.file.original_filename))
  end

  def destroy_taggings
    logger.debug "in destroy taggings"
    self.taggings.destroy_all
  end


  def show_value
    self.file_file_name
  end


end
