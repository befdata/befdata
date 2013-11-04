class AddDatabaseLevelColumnDefaults < ActiveRecord::Migration
  def up
    change_column_default :datacolumns, :datagroup_approved, false
    change_column_default :datacolumns, :datatype_approved, false
    change_column_default :datacolumns, :finished, false

    change_column_default :datagroups, :type_id, 1  # Datagrouptype::DEFAULT

    change_column_default :sheetcells, :status_id, 1  # Sheetcellstatus::UNPROCESSED
  end

  def down
    change_column_default :datacolumns, :datagroup_approved, nil
    change_column_default :datacolumns, :datatype_approved, nil
    change_column_default :datacolumns, :finished, nil

    change_column_default :datagroups, :type_id, nil

    change_column_default :sheetcells, :status_id, nil
  end
end
