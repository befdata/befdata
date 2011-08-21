class ImportCategory < ActiveRecord::Base
  belongs_to :datacolumn

  validates_presence_of :datacolumn
end