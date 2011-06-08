class Datafile < ActiveRecord::Base

#  attr_accessor :filename

  has_many :sheetcells, :as => :value        # which is not true: one categoricvalue can have many sheetcells
                                             # but a datafile, a numericvalue, etc has only one sheetcell
  has_one :dataset, :foreign_key => :upload_spreadsheet_id
  belongs_to :paperproposal

  validates_uniqueness_of :file_file_name

  has_attached_file :file,
  :basename => "basename",
  :path => ":rails_root/files/:filename",
  :url => "/files/:id/download"
  
  def basename
    return File.basename(self.file.original_filename, File.extname(self.file.original_filename))
  end

#  def initialize(filename)
#    @filename = filename
#    load_workbook
#  end
#
#  def columnheader
#    @columnheader  = Array(@book.worksheet(4).row(0)).compact
#    @columnheader
#  end
#
#  private
#
#  def load_workbook
#    @book = Spreadsheet.open filename
#    @book.io.close
#  end
end
