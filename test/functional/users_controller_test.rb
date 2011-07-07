require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  # Replace this with your real tests.
  test "should get index" do
    get :index
    assert_response :success
  end

  test "should get show user" do
    get :show, {:id => User.first.path_name}
    assert_response :success
  end

  test "should not show datasets with destroy me true" do
    get :show, :id => "Karin_Nadrowski"
    dataset = Dataset.find_by_title "Test species name import"
    assigned_datasets = assigns[:user_datasets_owned]
    assert !assigned_datasets.include?(dataset)
  end
end
