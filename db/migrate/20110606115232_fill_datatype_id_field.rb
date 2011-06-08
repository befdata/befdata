class FillDatatypeIdField < ActiveRecord::Migration
  def self.up
    sheetcells = Sheetcell.all.select
    sheetcells.each { |sc|
      datatype_id =
          case sc.value_type
            when "Textvalue" then 1
            when "Datetimevalue" then 2
            when "Categoricvalue" then 4
            when "Numericvalue" then 5
          end
        sc.update_attributes(:datatype_id => datatype_id)
     }
  end

  def self.down
    #raise ActiveRecord::IrreversibleMigration
  end
end
