class WorkbookValidator < ActiveModel::Validator
  def validate(record)
    record.errors.add :file, "could not be read." and return unless record.book

    record.errors.add :file, "is no valid workbook - has wrong number of pages" and return unless record.sheet_count == 5

    record.errors.add :base, "Workbook version number not found" and return if record.wb_version.blank?
    # check if first two numbers of version information match
    if record.wb_version.scan(/\A\d+\.\d+\./).first != Workbook::WBF[:wb_format_version].scan(/\A\d+\.\d+\./).first
      record.errors.add :base, "Workbook version not matching (#{wb_version} < #{Workbook::WBF[:wb_format_version]})"
      return
    end

    if record.headers.empty?
      record.errors.add :base, 'Sorry, we failed to find data in "raw data sheet". Please make sure the first row of it is not empty.'
      return
    end

    # check for unique column headers
    unless record.headers_unique?
      record.errors.add :base, "Column headers in the raw data sheet must be unique" and return
    end

    record.errors.add :base, 'Column headers should not be blank' and return if record.with_missing_headers?
  end
end
