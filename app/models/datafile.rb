## A Datafile references the uploaded "Dataworkboook" that the primary research data within a "Dataset" is derived from.

require "dataworkbook_format"

class Datafile < ActiveRecord::Base

  has_one :dataset, :foreign_key => :upload_spreadsheet_id

  validates_uniqueness_of :file_file_name
  validate :is_valid_worksheet

  has_attached_file :file,
  :basename => "basename",
  :path => ":rails_root/files/:filename",
  :url => "/files/:id/download"
  
  def basename
    return File.basename(self.file.original_filename, File.extname(self.file.original_filename))
  end

  def is_valid_worksheet
    if self.file.queued_for_write[:original]
      file_path = self.file.queued_for_write[:original].path
    else
      file_path = self.file.path
    end

    begin
      ss = Spreadsheet.open(file_path)
      ss.io.close
    rescue
      errors.add :file, "can not be read"
      return
    end

    unless ss && !ss.worksheet(Dataworkbook::WBF[:sheet_count]-1).nil? && ss.worksheet(Dataworkbook::WBF[:sheet_count]).nil?
      errors.add :file, "is no valid workbook - has wrong number of pages"
      return
    end

    wb_version = ss.worksheet(Dataworkbook::WBF[:metadata_sheet])[*Dataworkbook::WBF[:meta_version_pos]]
    if wb_version.blank?
      errors.add :file, "workbook version number not found"
      return
    end

    # check if first two numbers of version information match
    if wb_version.scan(/\A\d+\.\d+\./).first != Dataworkbook::WBF[:wb_format_version].scan(/\A\d+\.\d+\./).first
      errors.add :file, "workbook version not matching (#{wb_version} < #{Dataworkbook::WBF[:wb_format_version]})"
    end

  end
end
