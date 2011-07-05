module Admin::CategoricvaluesHelper

  def id_form_column(record, name)
    label :record, record.id
  end

  def sheetcells_form_column(record, name)
    label :record, record.sheetcells.size
  end

  def import_categoricvalues_form_column(record, name)
    label :record, record.import_categoricvalues.size
  end

  def sheetcells_column(record)
    record.sheetcells.size
  end

  def import_categoricvalues_column(record)
    record.import_categoricvalues.size
  end



end