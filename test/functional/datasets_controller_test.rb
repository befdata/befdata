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
    assert_nil flash[:error]
  end

  test "unlogged-in visitors can only download free_for_public datasets" do
    ds = Dataset.find_by_title "Test species name import second version"
    assert !ds.free_for_public?
    get :download, :id => ds.id
    assert_match(/Access denied/, flash[:error])

    flash.delete(:error)

    ds_public = Dataset.find_by_title("TITLE: use for visual testing of export")

    assert ds_public.free_for_public?
    get :download, :id => ds_public.id
    assert_nil flash[:error]
  end


  test "members can download free for members datasets" do
    user = User.find_by_login "Phdstudentnutrientcycling"
    login_user user.login
    ds = Dataset.find_by_title "Test species name import second version"

    assert ds.free_for_members && !user.has_roles_for?(ds)
    get :download, :id => ds.id
    assert_nil flash[:error]
  end

  test "members cann't download datasets not free for members" do
    user = User.find_by_login "Phdstudentnutrientcycling"
    login_user user.login
    ds = Dataset.find_by_title "Test species name import"
    #make sure the dataset is not free for members and user has no role about it.
    assert !(ds.free_for_members  || ds.free_for_public|| user.has_roles_for?(ds))
    get :download, :id=>ds.id
    assert_match(/Access denied/, flash[:error])
  end

  test "members can not download datasets belonging to other projects only" do
    user = User.find_by_login("Pidata")
    login_user user.login
    ds = Dataset.find_by_title "Unit tests"
    assert_not_equal user.projects, ds.projects
    assert !(ds.free_for_members || ds.free_for_public || user.has_roles_for?(ds))

    get :download, :id=>ds.id
    assert_match(/Access denied/, flash[:error])
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

    FileUtils.copy("#{Rails.root}/files/4_8346952459374534species first test.xls",
                     "#{Rails.root}/files/4_8346952459374534species first test.xls.tmp")
    login_nadrowski
    @dataset = Dataset.first

    old_workbook = @dataset.datacolumns.map(&:columnheader)

    #upload the same workbook again. This should not cause error.
    assert_nothing_raised {
      post :delete_imported_research_data_and_file, :id => @dataset.id,
             :datafile => {
                 :file =>  Rack::Test::UploadedFile.new("#{Rails.root}/files/4_8346952459374534species first test.xls")
             }
    }
    assert_nil flash[:error]
    assert_redirected_to dataset_path(@dataset)
    @dataset.reload
    assert_equal Dataworkbook.new(@dataset.upload_spreadsheet).columnheaders_raw,old_workbook


    #upload another workbook
    post :delete_imported_research_data_and_file, :id => @dataset.id,
          :datafile => {
              :file => fixture_file_upload("test_files_for_uploads/SP5_TargetSpecies_CN_final_8_target_spec_kn_-_short.xls")
          }

    assert_redirected_to dataset_path(@dataset)

    @dataset.reload
    assert_not_equal Dataworkbook.new(@dataset.upload_spreadsheet).columnheaders_raw, old_workbook

    #clean and recover
    @dataset.upload_spreadsheet.destroy
    FileUtils.copy("#{Rails.root}/files/4_8346952459374534species first test.xls.tmp",
                     "#{Rails.root}/files/4_8346952459374534species first test.xls")
  end

  test "should show new dataset page" do
    login_nadrowski
    get :new
  end
end
