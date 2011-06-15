require 'test_helper'

class ProjectsControllerTest < ActionController::TestCase
  # Replace this with your real tests.
  test "should get show project" do
    get Project.first
    assert_response :success
  end
end
