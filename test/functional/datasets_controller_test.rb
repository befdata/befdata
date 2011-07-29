require 'test_helper'

class DatasetsControllerTest < ActionController::TestCase
  setup :activate_authlogic

  test "after create freeformat file new dataset should be created" do
  # Arrange
  login_nadrowski

  freeformat_file = {:file => File.new(File.join(fixture_path, 'test_files_for_uploads', 'empty_test_file.txt'))}
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

  test "members can download free for members datasets" do
    user = User.find_by_login "Phdstudentnutrientcycling"
    login_user user.login
    ds = Dataset.find_by_title "Test species name import second version"

    assert (ds.free_for_members && !user.has_roles_for?(ds))
    get :download, :id => ds.id
    assert :success
  end

  
end
