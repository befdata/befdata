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

  # Freeformats

  test "download freeformat dataset should work" do
    # Arrange
    login_nadrowski
    f = Dataset.all.select{|d| d.freeformats.count > 0}.first.freeformats.first
    # Act
    get :download_freeformat, :id => f.id
    #Assert
    assert :success
  end

  test "freeformat download error message if inappropriate rights" do
    ds = f = Dataset.all.select{|d| d.freeformats.count > 0}.first
    user = (User.all.select{|u| !u.has_roles_for? ds} & non_admin_users).first
    assert !user.has_roles_for?(ds)
    f = ds.freeformats.first
    get :download_freeformat, :id => f.id
    assert_match /.*Access denied.*/, flash[:error]
  end

  test "freeformat download redirect to login if not for public" do
    f = Dataset.all.select{|d| d.freeformats.count > 0}.first.freeformats.first
    get :download_freeformat, :id => f.id
    assert_redirected_to login_url
    assert_match /.*Access denied.*/, flash[:error]
  end
  
end
