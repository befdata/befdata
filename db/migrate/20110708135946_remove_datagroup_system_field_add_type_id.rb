class RemoveDatagroupSystemFieldAddTypeId < ActiveRecord::Migration
  def self.up
    add_column :datagroups, :type_id, :integer

    datagroups = Datagroup.all.select
    datagroups.each { |dg|
      type_id = Datagrouptype::DEFAULT
      if(dg.title == "Category sheet match") then
        type_id = Datagrouptype::SHEETCATEGORYMATCH
      elsif(dg.title == "Helper") then
        type_id = Datagrouptype::HELPER
      end
      dg.update_attributes(:type_id => type_id)
     }

    remove_column :datagroups, :system
  end

  def self.down
    remove_column :datagroups, :type_id
    add_column :datagroups, :system, :boolean
  end
end
