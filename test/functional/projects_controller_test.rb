require 'test_helper'

class ProjectsControllerTest < ActionController::TestCase
  # Replace this with your real tests.
  test "should get show project" do
    get :show, {:id => Project.first.id}
    assert_response :success
  end
end
