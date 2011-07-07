require 'test_helper'

class TagsControllerTest < ActionController::TestCase
  test "should get show" do
    get :show, :id => Tag.first.id
    assert_response :success
  end

  test "should get index" do
    get :index
    assert_response :success
  end

  test "should not show datasets with destroy me true" do
    get :show, :id => Tag.find_by_name("dwc/terms/scientificNameAuthorship").id
    dataset = Dataset.find_by_title "Test species name import"
    assigned_datasets = assigns[:datasets]
    assert !assigned_datasets.include?(dataset)
  end

end
