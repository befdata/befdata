require 'test_helper'

class ImportsControllerTest < ActionController::TestCase
  setup :activate_authlogic

  test "creating freeformat dataset should work" do
    login_nadrowski
    freeformat = {:file => File.new(File.join(fixture_path, 'test_files_for_uploads', 'empty_freeformat_file.ppt'))}

    post(:create_dataset_freeformat, {:freeformat => freeformat})
    assert_response :redirect
  end
end
