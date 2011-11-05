## A Datafile references the uploaded "Dataworkboook" that the primary research data within a "Dataset" is derived from.
class Datafile < ActiveRecord::Base

  has_one :dataset, :foreign_key => :upload_spreadsheet_id
  belongs_to :paperproposal

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

    unless ss && !ss.worksheet(4).nil? && ss.worksheet(5).nil?
      errors.add :file, "is not according to worksheet specifications"
    end
  end

end
