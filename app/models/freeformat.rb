class Freeformat < ActiveRecord::Base

  belongs_to :paperproposal
  belongs_to :dataset

  validates_presence_of :file_file_name, :message => "You have to select a file to be uploaded."
  validates_presence_of :dataset, :message => "Freeformat must belong to a Dataset"

  has_attached_file :file,
  :basename => "basename",
  :path => ":rails_root/files/freeformats/:id_:filename",
  :url => "/files/freeformats/:id/download"

  def basename
    return File.basename(self.file.original_filename, File.extname(self.file.original_filename))
  end

  def to_label
    self.file_file_name.to_s
  end

end
