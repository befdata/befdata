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