class ExportedSheetcell < ActiveRecord::Base
  self.primary_key = :id
  belongs_to :datacolumn
end
