module Admin::DatasetsHelper

  def last_update_column(record)
    record.last_update.strftime "%Y-%m-%d %H:%M"
  end

end
