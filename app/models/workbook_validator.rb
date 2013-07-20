class WorkbookValidator < ActiveModel::Validator
  def validate(record)
    unless record.book
      record.errors.add :file, "could not be read." and return
    end
    ss = record.book

    unless ss && !ss.worksheet(Dataworkbook::WBF[:sheet_count]-1).nil? && ss.worksheet(Dataworkbook::WBF[:sheet_count]).nil?
      record.errors.add :file, "is no valid workbook - has wrong number of pages"
      return
    end

    wb_version = ss.worksheet(Dataworkbook::WBF[:metadata_sheet])[*Dataworkbook::WBF[:meta_version_pos]]
    record.errors.add :file, "workbook version number not found" and return if wb_version.blank?

    # check if first two numbers of version information match
    if wb_version.scan(/\A\d+\.\d+\./).first != Dataworkbook::WBF[:wb_format_version].scan(/\A\d+\.\d+\./).first
      record.errors.add :file, "workbook version not matching (#{wb_version} < #{Dataworkbook::WBF[:wb_format_version]})"
      return
    end

    # check for unique column headers
    column_headers = ss.worksheet(Dataworkbook::WBF[:data_sheet]).row(0).compact.map(&:strip).reject(&:empty?)
    unless column_headers.uniq_by(&:downcase).length == column_headers.length
      record.errors.add :file, "column headers in the raw data sheet must be unique" and return
    end
  end
end