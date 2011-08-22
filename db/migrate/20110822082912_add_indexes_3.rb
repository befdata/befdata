class AddIndexes3 < ActiveRecord::Migration
  def self.up
    # categories
    add_index :categories, [:datagroup_id]
    add_index :categories, [:status_id]

    # datagroups
    add_index :datagroups, [:type_id]
    remove_index :datagroups, [:id]

    # datasets_projects
    add_index :dataset_projects, [:dataset_id,:project_id]

    # dataset
    add_index :datasets, [:upload_spreadsheet_id]

    # import_categories
    add_index :import_categories, [:datacolumn_id]

    # free_formats
    add_index :freeformats, [:paperproposal_id]
    add_index :freeformats, [:dataset_id]

    # sheetcells
    add_index :sheetcells, [:category_id, :status_id, :datacolumn_id]
  end

  def self.down
    # categories
    remove_index :categories, [:datagroup_id]
    remove_index :categories, [:status_id]

    # datagroups
    remove_index :datagroups, [:type_id]
    add_index :datagroups, [:id]

    # datasets_projects
    remove_index :dataset_projects, [:dataset_id,:project_id]

    # dataset
    remove_index :datasets, [:upload_spreadsheet_id]

    # import_categories
    remove_index :import_categories, [:datacolumn_id]

    # free_formats
    remove_index :freeformats, [:paperproposal_id]
    remove_index :freeformats, [:dataset_id]

    # sheetcells
    remove_index :sheetcells, [:category_id, :status_id, :datacolumn_id]
  end
end
