# Sheetcell entries are pointing at the raw data obtained from
# measuring something.
#
# The accepted value of the data is stored in the accepted_value field unless
# the "Datatype" is a "Category" where the category id is stored instead.
class Sheetcell < ActiveRecord::Base

  belongs_to :datacolumn
  belongs_to :category, :dependent => :destroy
  after_initialize :set_default_status

  def set_default_status
    if @new_record
      self.status_id = Sheetcellstatus::UNPROCESSED
    end
  end

  # Datatypes are defined in config/initializers/datatype_load.rb and the valitation procedures are 
  # stored in https://github.com/befdata/befdata/blob/master/db/non_schema_sql.sql
  def datatype
    if(!self.datatype_id.nil?)
      return Datatypehelper.find_by_id(self.datatype_id)
    else
      return nil
    end
  end

  def same_entry_cells
    self.datacolumn.sheetcells.where(["import_value = ?", self.import_value])
  end

  # returns the accepted data for the sheet cell
  # we need to check that the category exists as it might not
  def show_value
    if(!self.datatype.nil?)
      if(self.datatype.is_category? && !self.category.nil?)
        return self.category.show_value
      else
        # todo: we should format the field based on the datatype
        return self.accepted_value
      end
    end
  end

  def export_value
    value = nil
    if self.datatype && self.datatype.is_category? && self.category
      value = self.category.short
    elsif self.datatype && self.datatype.name.match(/^date/) && self.accepted_value
      value = self.accepted_value.to_date.to_s
    elsif self.accepted_value
      value = self.accepted_value
    else
      value = self.import_value
    end
    value
  end

end
