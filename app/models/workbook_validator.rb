class WorkbookValidator < ActiveModel::Validator
  def validate(record)
    ss = record.book

    record.errors.add :file, "could not be read." and return unless ss
    record.errors.add :file, "is no valid workbook - has wrong number of pages" and return if ss.worksheets.count != 5

    wb_version = record.wb_version
    record.errors.add :file, "workbook version number not found" and return if wb_version.blank?

    # check if first two numbers of version information match
    if wb_version.scan(/\A\d+\.\d+\./).first != Dataworkbook::WBF[:wb_format_version].scan(/\A\d+\.\d+\./).first
      record.errors.add :file, "workbook version not matching (#{wb_version} < #{Dataworkbook::WBF[:wb_format_version]})"
      return
    end

    # check for unique column headers
    unless record.columnheaders_unique?
      record.errors.add :file, "column headers in the raw data sheet must be unique" and return
    end
  end
end