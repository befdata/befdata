require 'test_helper'

class DataSetTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "any dataset can have zero to many projects linked" do
    p_datasets = projects("projects_001").datasets
    assert p_datasets
  end

  test "datasets are associated to dataset projects" do
    dataset = datasets("datasets_001")
    assert !dataset.dataset_projects.nil?
  end

  test "clean a dataset should delete all sheetcells" do
    dataset = datasets("datasets_001")
    all_sheetcells_length = Sheetcell.count
    dataset_sheetcells_length = dataset.sheetcells.length
    sheetcells_expected_length = all_sheetcells_length - dataset_sheetcells_length

    dataset.clean

    assert_equal(sheetcells_expected_length, Sheetcell.count)
  end

  test "clean a dataset should delete all datacolumns" do
    dataset = datasets("datasets_001")
    all_columns_length = Datacolumn.count
    datacolumns_length = dataset.datacolumns.length
    datacolumns_expected_length = all_columns_length - datacolumns_length
    
    dataset.clean
    
    assert_equal(datacolumns_expected_length, Datacolumn.count)
  end

  test "clean a dataset should delete not needed datagroups" do
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

  test "clean a dataset should delete all import categoric values" do
    dataset = datasets("datasets_001")
    all_import_values = ImportCategory.count
    import_categories_length = dataset.datacolumns.collect{|dc| dc.import_categories}.flatten.compact.length
    import_categories_expected_length = all_import_values - import_categories_length

    dataset.clean

    assert_equal(import_categories_expected_length, ImportCategory.count)
  end


  test "clean a dataset should delete categoric values" do
    dataset = datasets("datasets_001")

    assert_difference 'Categoricvalue.count', -2 do
      dataset.clean
    end
  end

  test "clean a dataset should delete all values" do
    dataset = datasets("datasets_001")
    all_values = Textvalue.count
    all_values += Numericvalue.count
    all_values += Datetimevalue.count
    all_values += Categoricvalue.count

    assert_difference 'Textvalue.count + Numericvalue.count + Datetimevalue.count + Categoricvalue.count', -13 do
      dataset.clean
    end
  end

  test "clean a dataset should delete all observations" do
    dataset = datasets("datasets_001")

    assert_difference 'Observation.count', -4 do
      dataset.clean
    end
  end

  test "clean a dataset should delete all freeformats" do
    dataset = datasets("datasets_001")

    assert_difference 'Freeformat.count', 0 do
      dataset.clean
    end
  end

  test "clean a dataset should delete the datafile" do
    dataset = datasets("datasets_001")

    assert_difference 'Datafile.count', -1 do
      dataset.clean
    end
  end

  test "clean a dataset should not delete the associated projects" do
    dataset = datasets("datasets_001")

    assert_difference 'DatasetProject.count', 0 do
      dataset.clean
    end
  end

  test "clean a dataset should not delete the associated people" do
    dataset = datasets("datasets_001")


    assert_difference 'dataset.accepted_roles.count', 0 do
      dataset.clean
    end
  end

  test "clean a dataset should delete the associated people from datacolumns" do
    dataset = datasets("datasets_001")
    associated_people = 0
    dataset.datacolumns do |datacolumn|
      associated_people_length += datacolumn.accepted_roles.length
    end

    dataset.clean

    pending "not working"
  end
end
