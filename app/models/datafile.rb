class Datafile < ActiveRecord::Base
  belongs_to :dataset

  has_attached_file :file, :basename => "basename",
      :path => ":rails_root/files/:id_:filename",
      :url => "/files/:id/download"
  validates_attachment_presence :file

  def basename
    return File.basename(self.file.original_filename, File.extname(self.file.original_filename))
  end

  def path
    file.queued_for_write[:original] ? file.queued_for_write[:original].path : file.path
  end

  def spreadsheet
    return nil unless file.present?
    return @spreadsheet if defined? @spreadsheet
    @spreadsheet = case File.extname(path)
      when '.xls' then Dataworkbook.new(self)
      when '.csv' then CsvData.new(self)
      else nil
    end
  end
  delegate :import_data, :general_metadata_hash, :authors_list, :projects_list, :to => :spreadsheet, :allow_nil => true

  validate :check_spreadsheet, :if => Proc.new {file.present?}
  def check_spreadsheet
    self.errors[:base] = 'We currently only support Excel-2003 and CSV files.' and return if spreadsheet.nil?
    unless spreadsheet.valid?
      spreadsheet.errors.to_hash.each do |k, v|
        self.errors.add k, v
      end
    end
  end
end
