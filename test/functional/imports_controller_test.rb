require 'test_helper'
require "authlogic/test_case"

class ImportsControllerTest < ActionController::TestCase
  setup :activate_authlogic

  test "creating freeformat dataset and deleting should work" do
    # Arrange
    nadrowski = users(:users_006)
    UserSession.create(nadrowski)

    freeformat = {:file => File.new(File.join(fixture_path, 'files', 'People.ppt'))}

    # Act
    post(:create_dataset_freeformat, {:freeformat => freeformat})

    #Assert
    assert_response :redirect
  end
end
