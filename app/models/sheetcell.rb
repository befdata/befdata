# Measurement entries are pointing at the raw data obtained from
# measuring something.
#
# The accepted value of the data is stored in the accepted_value field unless
# the data type is
#
# One measurement can link to more than one Observation entries
# through the table ObservationsMeasurement. But in most of the cases,
# one Measurement will belong to only one Observation.

class Sheetcell < ActiveRecord::Base

  belongs_to :observation, :dependent => :destroy
  belongs_to :datacolumn
  belongs_to :category
  after_initialize :init

  # set the default value for status_id
  def init
    #if(!self.attributes["status_id"].nil?)
    #  if(self.status_id.nil?)
    #    self.status_id = Sheetcellstatus::UNPROCESSED
    #  end
    #end

    if(@new_record)
      self.status_id = Sheetcellstatus::UNPROCESSED
    end
  end

  def datatype
    if(!self.datatype_id.nil?)
      return Datatypehelper.find_by_id(self.datatype_id)
    else
      return nil
    end
  end

  def same_entry_cells
    all_cells = self.datacolumn.sheetcells
    same_entry_cells = all_cells.
      select{|cell| cell.import_value == self.import_value}.flatten
    return same_entry_cells
  end

  # returns the accepted data for the sheet cell
  # we need to check that the category exists as it might not
  def show_value
    if(!self.datatype.nil?)
      if(self.datatype.iscategory && !self.category.nil?)
        return self.category.show_value
      else
        # todo: we should format the field based on the datatype
        return self.accepted_value
      end
    end
  end

end
