require 'test_helper'

class DataSetTest < ActiveSupport::TestCase
  self.use_transactional_fixtures = false
  def setup
    FileUtils.copy("#{Rails.root}/files/4_8346952459374534species first test.xls",
              "#{Rails.root}/files/4_8346952459374534species first test.xls.tmp")
  end

  def teardown
    FileUtils.move("#{Rails.root}/files/4_8346952459374534species first test.xls.tmp",
              "#{Rails.root}/files/4_8346952459374534species first test.xls",
              :force => true)
  end

  # Replace this with your real tests.
  test "any dataset can have zero to many projects linked" do
    p_datasets = projects("projects_001").datasets
    assert p_datasets
  end

  test "delete_imported_research_data_and_file should delete all sheetcells" do
    dataset = datasets("datasets_001")
    all_sheetcells_length = Sheetcell.count
    dataset_sheetcells_length = dataset.sheetcells.length
    sheetcells_expected_length = all_sheetcells_length - dataset_sheetcells_length

    dataset.delete_imported_research_data_and_file

    assert_equal(sheetcells_expected_length, Sheetcell.count)
  end

  test "delete_imported_research_data_and_file should delete all datacolumns" do
    dataset = datasets("datasets_001")
    all_columns_length = Datacolumn.count
    datacolumns_length = dataset.datacolumns.length
    datacolumns_expected_length = all_columns_length - datacolumns_length
    
    dataset.delete_imported_research_data_and_file
    
    assert_equal(datacolumns_expected_length, Datacolumn.count)
  end

  test "delete_imported_research_data_and_file should delete not needed datagroups" do
    dataset = datasets("datasets_001")
    all_datagroups_length = Datagroup.count

    datagroups_for_deletion = []
    dataset.datacolumns.each do |dc|
      datagroup = dc.datagroup
      if datagroup.datacolumns == 1
        datagroups_for_deletion << datagroup
      end
    end
    datagroup_expected_length = all_datagroups_length - datagroups_for_deletion.length

    assert_equal(datagroup_expected_length, Datagroup.count)
  end

  test "delete_imported_research_data_and_file should delete all import categoric values" do
    dataset = datasets("datasets_001")
    all_import_values = ImportCategory.count
    import_categories_length = dataset.datacolumns.collect{|dc| dc.import_categories}.flatten.compact.length
    import_categories_expected_length = all_import_values - import_categories_length

    dataset.delete_imported_research_data_and_file

    assert_equal(import_categories_expected_length, ImportCategory.count)
  end


  test "delete_imported_research_data_and_file should delete categoric values" do
    #TODO check if we still need this test (Categoricvalues do no longer exist) see #4772
    #dataset = datasets("datasets_001")
    #
    #assert_difference 'Categoricvalue.count', -2 do
    #  dataset.delete_imported_research_data_and_file
    #end
  end

  test "delete_imported_research_data_and_file should delete all values" do
    #TODO check if we still need this test (Categoricvalues etc do no longer exist) see #4772
    #dataset = datasets("datasets_001")
    #all_values = Textvalue.count
    #all_values += Numericvalue.count
    #all_values += Datetimevalue.count
    #all_values += Categoricvalue.count
    #
    #assert_difference 'Textvalue.count + Numericvalue.count + Datetimevalue.count + Categoricvalue.count', -13 do
    #  dataset.delete_imported_research_data_and_file
    #end
  end

  test "delete_imported_research_data_and_file should delete all freeformats" do
    dataset = datasets("datasets_001")

    assert_difference 'Freeformat.count', 0 do
      dataset.delete_imported_research_data_and_file
    end
  end

  test "delete_imported_research_data_and_file should delete the datafile" do
    dataset = datasets("datasets_001")

    assert_difference 'Datafile.count', -1 do
      dataset.delete_imported_research_data_and_file
    end
  end

  test "delete_imported_research_data_and_file should not delete the associated projects" do
    dataset = datasets("datasets_001")
    previous_associated_projects = dataset.projects

    dataset.delete_imported_research_data_and_file

    assert_equal previous_associated_projects, dataset.projects
  end

  test "delete_imported_research_data_and_file should not delete the associated people" do
    dataset = datasets("datasets_001")


    assert_difference 'dataset.accepted_roles.count', 0 do
      dataset.delete_imported_research_data_and_file
    end
  end

  test "delete_imported_research_data_and_file should delete the associated people from datacolumns" do
    dataset = datasets("datasets_001")
    associated_people = 0
    dataset.datacolumns do |datacolumn|
      associated_people_length += datacolumn.accepted_roles.length
    end

    dataset.delete_imported_research_data_and_file

    pending "not working"
  end

  test "update_column_should_update_dataset_updated_at" do
      datacolumn = Datacolumn.find(33)
      updated_at = datacolumn.dataset.updated_at
      datacolumn.columnheader += "_test"
      datacolumn.save

      assert_not_equal updated_at, datacolumn.dataset.updated_at
    end

    test "validate_datagroup_should_update_dataset_updated_at" do
      datacolumn = Datacolumn.find(48)
      updated_at = datacolumn.dataset.updated_at
      datacolumn.approve_datagroup(datacolumn.datagroup)

      assert_not_equal updated_at, datacolumn.dataset.updated_at
    end

    test "validate_datatype_should_update_dataset_updated_at" do
      datacolumn = Datacolumn.find(48)
      updated_at = datacolumn.dataset.updated_at
      datacolumn.approve_datatype("number", User.find(1))

      assert_not_equal updated_at, datacolumn.dataset.updated_at
    end

end
