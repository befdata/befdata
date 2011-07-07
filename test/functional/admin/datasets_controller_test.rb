require 'test_helper'

class Admin::DatasetsControllerTest < ActionController::TestCase
  setup :activate_authlogic

  test "should get index" do
    login_nadrowski
    get :index
    assert_response :success
    assert_template 'list'
  end

  test "show destroy_me in index" do
    login_nadrowski
    get :index
    m = Dataset.find_all_by_destroy_me(true).empty? ? '' : '[checked=checked]'
    m = ''
    assert_select "td.destroy_me-column > input[type=checkbox]#{m}"
  end

  test "show destroy_me in update" do
    login_nadrowski
    @dataset = Dataset.where("destroy_me = true").first
    get :edit, :id => @dataset.id
    assert_select "input.destroy_me-input[checked=checked]"
  end
  
end
