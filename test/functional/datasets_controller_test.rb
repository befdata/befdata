require 'test_helper'

class DatasetsControllerTest < ActionController::TestCase
  setup :activate_authlogic

  test "after create freeformat file new dataset should be created" do
  # Arrange
  nadrowski = users(:users_006)
  UserSession.create(nadrowski)

  freeformat_file = {:file => File.new(File.join(fixture_path, 'test_files_for_upload', 'empty_test_file.txt'))}
  freeformat = Freeformat.create(freeformat_file)

  # Act
  get(:upload_dataset_freeformat, :freeformat_id => freeformat.id)

  #Assert
  assert_response :success
  assert_select 'div#content', /empty_test_file.txt/
  end

  test "download freeformat dataset should work" do
  # Arrange

  # Act

  #Assert
  end

  test "should get show dataset" do
    get :show, {:id => Dataset.first.id}
    assert_response :success
  end

  
end
