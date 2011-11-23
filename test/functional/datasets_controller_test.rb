require 'test_helper'

class DatasetsControllerTest < ActionController::TestCase
  setup :activate_authlogic

  test "should get show dataset" do
    get :show, {:id => Dataset.first.id}
    assert_response :success
  end

  test "should show eml metadata as xml" do
    get :show, {:id => Dataset.first.id, :format => :eml}
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
