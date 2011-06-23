class FillOptimisationFieldsInSheetcells < ActiveRecord::Migration
  def self.up
    # take the existing value of the sheetcell and place it in the new accepted_value field
    # unless the data type is categoric value, in this case place the id of the categoric value in the new category_id field
    sheetcells = Sheetcell.all.select
    sheetcells.each { |sc|
      if (sc.value_type == "Categoricvalue")
        sc.update_attributes(:category_id => sc.value_id)
      else
        value =
          case sc.value_type
            when "Numericvalue" then sc.value.number
            when "Datetimevalue" then sc.value.year
            when "Textvalue" then sc.value.text
          end
        sc.update_attributes(:accepted_value => value)
      end
     }
  end

  def self.down
    #raise ActiveRecord::IrreversibleMigration
  end
end
