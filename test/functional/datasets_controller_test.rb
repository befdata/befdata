require 'test_helper'

class DatasetsControllerTest < ActionController::TestCase
  setup :activate_authlogic

  test "after create freeformat file new dataset should be created" do
    login_nadrowski
    file = {:file => File.new(File.join(fixture_path, 'test_files_for_uploads', 'empty_test_file.txt'))}
    
    get(:create_dataset_with_freeformat_file, :freeformat => file)

    assert_response :success
    assert_select 'div#content', /empty_test_file.txt/
  end

  test "should get show dataset" do
    get :show, {:id => Dataset.first.id}
    assert_response :success
  end

  test "dataset can be downloaded" do
    login_nadrowski
    ds = Dataset.find_by_title "Test species name import second version"

    get :download, :id => ds.id
    assert :success
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
    login_nadrowski

    get :download_freeformat, :id => Freeformat.first

    assert :success
  end

  test "freeformat download error message if inappropriate rights" do
    ds = Dataset.find_by_title "Unit tests"
    f = ds.freeformats.first
    user = User.find_by_login "pinutrientcycling"

    login_user user.login
    @request.env['HTTP_REFERER'] = login_url

    assert ds.freeformats.count > 0
    assert !user.has_roles_for?(ds) && !user.has_role?(:admin)

    get :download_freeformat, :id => f.id
    assert_match /.*Access denied.*/, flash[:error]
  end

  test "freeformat download redirect to login if not for public" do
    ds = Dataset.find_by_title "Unit tests"
    f = ds.freeformats.first
    get :download_freeformat, :id => f.id

    assert_redirected_to login_url
    assert_match /.*Access denied.*/, flash[:error]
  end
  
  # Data 
  
  test "data method should display all datacolumns" do
    pending "Implement me!"
  end
  
  # Destroy
  
  test "destroy should delete a dataset" do
    pending "Implement me!"  
  end

  test "replacing original research data with new file" do
    login_nadrowski

    @dataset = Dataset.first

    post :delete_imported_research_data_and_file, :id => @dataset.id,
          :datafile => {
              :file => fixture_file_upload("test_files_for_uploads/SP5_TargetSpecies_CN_final_8_target_spec_kn_-_short.xls")
          }

    assert_redirected_to data_dataset_path(@dataset)

    FileUtils.rm("#{Rails.root}/files/SP5_TargetSpecies_CN_final_8_target_spec_kn_-_short.xls")
  end
end
