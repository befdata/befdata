require 'test_helper'
require "authlogic/test_case"

class DatasetsControllerTest < ActionController::TestCase
  setup :activate_authlogic

  test "after create freeformat file new dataset should  created" do
  # Arrange
  nadrowski = users(:users_006)
  UserSession.create(nadrowski)

  freeformat_file = {:file => File.new(File.join(fixture_path, 'files', 'empty_test_file.txt'))}
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

  test "show freeformat dataset should work" do
  # Arrange

  # Act

  #Assert
  end
end
