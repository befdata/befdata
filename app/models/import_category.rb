## The ImportCategory class represents the "Category" values stored in the "Categories" sheet of the MS Excel Workbook (Dataworkbook class).
## These are the user-defined categories that will be used during the validation process if "Category" does not already exist in the portal
## within the correct "Datagroup".

class ImportCategory < ActiveRecord::Base
  belongs_to :datacolumn

  validates_presence_of :datacolumn, :short, :long, :description
  before_validation :try_filling_missing_values

  def try_filling_missing_values
    if self.short then
      self.long ||= self.short
      self.description ||= self.long
    end
  end
end