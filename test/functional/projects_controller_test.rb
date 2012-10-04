require 'test_helper'

class ProjectsControllerTest < ActionController::TestCase
  # Replace this with your real tests.
  test "should get show project" do
    get :show, {:id => Project.first.id}
    assert_success_no_error
  end
end
