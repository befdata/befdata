class ImportCategoricvalue < ActiveRecord::Base
  belongs_to :datacolumn
  belongs_to :category # no dependent destroy anymore, since that may be the bottleneck in
                             # performance when deleting datacolumns

  validates_presence_of :datacolumn, :category
end
