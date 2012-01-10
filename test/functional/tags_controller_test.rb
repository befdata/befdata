require 'test_helper'

class TagsControllerTest < ActionController::TestCase
  test "should get show" do
    get :show, :id => ActsAsTaggableOn::Tag.first.id
    assert_response :success
  end

  test "should get index" do
    get :index
    assert_response :success
  end

end
