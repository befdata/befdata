## A Freeformat file is an asset file that has been uploaded to the application within a "Dataset". A "Dataset" can have
## none, one or more than one Freeformat files. No validation is performed on a Freeformat file.
class Freeformat < ActiveRecord::Base

  belongs_to :freeformattable, :polymorphic => true

  validates_presence_of :file_file_name, :message => "You have to select a file to be uploaded."
  validates_presence_of :freeformattable, :message => "Freeformat must belong to something"

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
