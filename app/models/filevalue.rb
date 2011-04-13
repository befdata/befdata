class Filevalue < ActiveRecord::Base

  has_many :sheetcells, :as => :value        # which is not true: one categoricvalue can have many sheetcells
                                             # but a filevalue, a numericvalue, etc has only one sheetcell
  has_one :dataset, :foreign_key => :upload_spreadsheet_id
  belongs_to :paperproposal
  
  validates_uniqueness_of :file_file_name

  has_attached_file :file,
  :basename => "basename",
  :path => ":rails_root/files/:filename",
  :url => "files/:id/download"



  def basename
    return File.basename(self.file.original_filename, File.extname(self.file.original_filename))
  end
end
