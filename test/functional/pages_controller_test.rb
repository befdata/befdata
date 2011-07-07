require 'test_helper'

class PagesControllerTest < ActionController::TestCase
  test "should get home" do
    get :home
    assert_response :success
  end

  test "should get impressum" do
    get :impressum
    assert_response :success
  end

  test "should get help" do
    get :help
    assert_response :success
  end

  test "sould get data" do
    get :data
    assert_response :success
  end

  test "should not show datasets with destroy me true" do
    get :data
    dataset = Dataset.where("destroy_me = true").first
    assigned_datasets = assigns[:datasets]
    assert !assigned_datasets.include?(dataset)
  end
end
