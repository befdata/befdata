class ImportCategoricvalue < ActiveRecord::Base
  belongs_to :datacolumn
  belongs_to :categoricvalue, :dependent => :destroy

  validates_presence_of :datacolumn, :categoricvalue
end
