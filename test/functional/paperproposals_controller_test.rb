require 'test_helper'

class PaperproposalsControllerTest < ActionController::TestCase
  setup :activate_authlogic

  test "should get index" do
    login_nadrowski
    get :index
    assert_response :success
  end

  test "without login should not show the index and should redirect to login" do
    get :index
    assert_redirected_to :login
  end

  test "should get new" do
    login_nadrowski
    get :new
    assert_response :success
  end

  test "should post new paperproposal" do
    login_nadrowski
    
    post :create, :paperproposal => {:title => "Test", :rationale => "Rational"}
    @paperproposal = Paperproposal.find_by_title("Test")

    assert_redirected_to edit_paperproposal_path(@paperproposal)
  end

  test "should add datasets to paperproposal and the author list is changed" do
    login_and_load_paperproposal "Step 1 Paperproposal"
    @dataset_with_michael = Dataset.find_by_title("Test species name import second version")

    
    get :edit, :id => @paperproposal.id
    assert_select "div#datasets li", {:count => Dataset.count}
    assert_select "div#author-list li#potential ul li", false

    put :update, :id => @paperproposal.id, :datasets => [@dataset_with_michael.id], :aspect => {"#{@dataset_with_michael.id}" => "main"}
    assert_redirected_to edit_paperproposal_path(@paperproposal)

    get :edit, :id => @paperproposal.id    
    assert_select "div#author-list li#potential ul", {:text=> /Michael/}
  end


  
  test "should add file to paperproposal should work" do
    login_and_load_paperproposal "Step 1 Paperproposal"
    paperproposal_file = {:file => File.new(File.join(fixture_path, 'test_files_for_uploads', 'empty_test_file.txt'))}


    put :update, :id => @paperproposal.id, :paperproposal => {:datafiles_attributes => {"0" => paperproposal_file}}

    assert_redirected_to edit_paperproposal_path(@paperproposal)

    get :edit, :id => @paperproposal.id
    assert_select "div#files", {:text=> /empty_test_file/}
  end

  test "should not send to board if no dataset is set" do
    login_and_load_paperproposal "Step 1 Paperproposal"

    get :edit, :id => @paperproposal.id
    assert_response :success

    assert_select "form#update_state_edit", false, "Without any dataset you can not send to board"
  end

  test "should send to board if it is possible" do

  end

  test "for project board it should be possible to..." do

  end

  test "project board can reject the paperproposal" do

  end

  test "it should be possible to edit a rejected paperproposal" do

  end

  test "it should not be possible to edit a paperproposal in vote" do

  end

  test "should show a paperproposal for owner" do

  end

  test "should show a paperproposal for project board if they can vote for it" do

  end

  test "should show a paperproposal for dataset owner and responsible if they can vote" do

  end  
  
end
