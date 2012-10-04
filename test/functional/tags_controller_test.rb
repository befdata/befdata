require 'test_helper'

class TagsControllerTest < ActionController::TestCase
  test "should get show" do
    get :show, :id => ActsAsTaggableOn::Tag.first.id
    assert_success_no_error
  end

  test "should get index" do
    get :index
    assert_success_no_error
  end

end
