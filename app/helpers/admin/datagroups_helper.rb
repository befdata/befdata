module Admin::DatagroupsHelper

  def datacolumns_column (record)
    record.datacolumns.size
  end

  def datacolumns_form_column (record, name)
    label :record, record.datacolumns.size
  end

end
