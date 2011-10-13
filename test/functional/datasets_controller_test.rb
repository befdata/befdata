require 'test_helper'

class DatasetsControllerTest < ActionController::TestCase
  setup :activate_authlogic

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
  test "add freeformat to dataset and change it and delete it" do
    login_nadrowski
    dataset = Dataset.first
    f = File.new(File.join(fixture_path, 'test_files_for_uploads', 'empty_test_file.txt'))
    file = {:file => f}

    request.env["HTTP_REFERER"] = edit_dataset_path dataset
    get(:add_dataset_freeformat_file, :id => dataset.id, :freeformat => file)

    get(:edit, :id => dataset.id)
    assert_select 'div#content', /empty_test_file.txt/

    #and now change it...
    freeformat = Freeformat.all.select{|ff| ff.file_file_name.match(/empty_test_file.txt/) && ff.dataset == dataset}.first
    f =  File.new(File.join(fixture_path, 'test_files_for_uploads', 'empty_freeformat_file.ppt'))
    hash = {:file => f, :id => freeformat.id}

    get(:update_dataset_freeformat_file, :id => dataset.id, :freeformat => hash)

    get(:edit, :id => dataset.id)
    assert_select 'div#content', /empty_freeformat_file.ppt/
    assert_select 'div#content', {:text => /empty_test_file.txt/, :count => 0}, "exchanged test file not gone"

    #now delete it
    get(:delete_dataset_freeformat_file, :id => freeformat.id)

    get(:edit, :id => dataset.id)
    assert_select 'div#content', {:text => /empty_freeformat_file.ppt/, :count => 0}, "deleted test file not gone"
  end

  test "download freeformat file should work" do
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
