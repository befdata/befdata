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
    begin
      Dataworkbook.new self
    rescue
      errors.add :file, "is no valid worksheet"
    end
  end

end
