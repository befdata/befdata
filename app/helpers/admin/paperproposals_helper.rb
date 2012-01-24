module Admin::PaperproposalsHelper

  def authors_column(record)
    record.beautiful_title(true)
  end

end