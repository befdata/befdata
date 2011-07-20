class AddDatagroupForSheetCategories < ActiveRecord::Migration
  def self.up
    datagroup = Datagroup.find_by_type_id(Datagrouptype::SHEETCATEGORYMATCH)
    unless datagroup
      Datagroup.create(:title=> "Sheet category match",
                       :description=> "Sheet category match",
                       :type_id => Datagrouptype::SHEETCATEGORYMATCH)
    end
  end

  def self.down

  end
end
