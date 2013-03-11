require 'test_helper'

class PaperproposalsControllerTest < ActionController::TestCase
  setup :activate_authlogic

  test "should get index" do
    get :index
    assert_success_no_error
  end

  test "should get index as csv" do
    login_nadrowski
    get :index_csv
    assert_success_no_error
  end

  test "without login should not be able to edit" do
    @request.env['HTTP_REFERER'] = login_url
    get :edit, :id => Paperproposal.first.id
    assert_match /.*Access denied.*/, flash[:error]
  end

  test "should get new" do
    login_nadrowski
    get :new
    assert_success_no_error
  end

  test "create new paperproposal" do
    login_nadrowski
    
    post :create, :paperproposal => {:title => "Test", :rationale => "Rational"}
    @paperproposal = Paperproposal.find_by_title("Test")

    assert_redirected_to edit_datasets_paperproposal_path(@paperproposal)
  end

  test "should have initital title same as the title after creation process" do
    login_nadrowski

    post :create, :paperproposal => {:title => "Test", :rationale => "Rational"}
    @paperproposal = Paperproposal.find_by_title("Test")

    assert_equal "Test", @paperproposal.initial_title
  end

  test "show paperproposal" do
    login_nadrowski
    get :show, :id => 1
    assert_success_no_error
  end

  test "show metadata edit" do
    login_nadrowski
    get :edit, :id => 1
    assert_success_no_error
  end

  test "show manage datasets" do
    login_nadrowski
    get :edit_datasets, :id => 1
    assert_success_no_error
  end

  test "show manage freeformat files" do
    login_nadrowski
    get :edit_files, :id => 1
    assert_success_no_error
  end

  test "updating also refreshes author list" do
    login_nadrowski
    paperproposal = Paperproposal.find 1
    old_authors_count = paperproposal.all_authors_ordered.count
    post :update, :id => paperproposal.id, :paperproposal => {:envisaged_journal => 'testjournal'}, :people => [5,3,4]
    paperproposal.reload
    assert old_authors_count > paperproposal.all_authors_ordered.count
  end

  test "vote on paperproposal is reflected in ui" do
    login_nadrowski
    paperproposal = Paperproposal.find 5
    vote = PaperproposalVote.find 1
    get :update_vote, :id => vote.id, :paperproposal_vote => {:vote => 'accept'}
    get :show, :id => paperproposal.id
    assert_success_no_error
    assert_select 'img[alt="Arrow_right_accept"]'
  end

  test "should add datasets to paperproposal and the author list is changed" do
    login_and_load_paperproposal "nadrowski", "Step 1 Paperproposal"
    @dataset_with_michael = Dataset.find_by_title("Test species name import second version")
    old_authors_count = @paperproposal.all_authors_ordered.count

    get :edit_datasets, :id => @paperproposal.id
    assert_select "tbody tr", {:count => 0}

    post :update_datasets, :id => @paperproposal.id, :dataset_ids => [@dataset_with_michael.id], :aspect => {@dataset_with_michael.id.to_s => "main"}
    assert_redirected_to paperproposal_path(@paperproposal)

    @paperproposal.reload
    assert_equal 1, @paperproposal.datasets.count
    assert old_authors_count < @paperproposal.all_authors_ordered.count

    get :show, :id => @paperproposal.id
    assert_select "span.comma-separated-list", /.*Michael.*/, response.body
  end

  test "should not send to board if no dataset is set" do
    login_and_load_paperproposal "nadrowski", "Step 1 Paperproposal"

    get :edit, :id => @paperproposal.id
    assert_success_no_error

    assert_select "form#update_state_edit", false, "Without any dataset you can not send to board"
  end

  test "should send to board if it is possible" do
    login_and_load_paperproposal "pinutrientcycling", "Step 2 Paperproposal"

    post :update_state, :id => @paperproposal.id, :paperproposal => {:board_state => "submit"}
    @paperproposal.reload

    assert (@paperproposal.board_state == "submit")
    assert_redirected_to @paperproposal
  end

  test "should show [Submitted to board, waiting for acceptance.] after send to project board" do
    login_and_load_paperproposal "pinutrientcycling", "Step 2 Paperproposal"

    post :update_state, :id => @paperproposal.id, :paperproposal => {:board_state => "submit"}

    get :show, :id => @paperproposal.id

    assert_success_no_error
    assert_select "div", {:text => /Submitted to board, waiting for acceptance./}
  end

  test "for project board member it should be possible to vote" do
    pending "Untestable because vote is in view of user controller and action in paperproposal"
  end

  test "project board can reject the paperproposal" do
    pending "Untestable because vote is in view of user controller and action in paperproposal"
  end

  test "it should be possible to edit a rejected paperproposal" do
    login_and_load_paperproposal "nadrowski", "Step 3 Paperproposal rejected"

    get :edit, :id => @paperproposal.id

    assert_success_no_error
  end

  test "it should not be possible to edit a paperproposal in vote" do
    pending "but it is still possible"
#    login_and_load_paperproposal "pinutrientcycling", "Step 3 Paperproposal"
#
#    get :edit, :id => @paperproposal.id
#
#    assert_response :redirect
  end

  test "should show a paperproposal for owner" do
    pending "paperproposal is show for everybody."
  end

  test "should show a paperproposal for project board if they can vote for it" do
    pending "paperproposal is show for everybody."
  end

  test "should show a paperproposal for dataset owner and responsible if they can vote" do
    pending "paperproposal is show for everybody."
  end

  test "should not show the initial title on create page" do
    login_nadrowski

    get :new

    assert_select 'div#content' do |element|
      assert !(element.first =~ /Initial title/)
    end
  end

  test "should allow download of datasets to paperproposers if final" do
    pending "functionality not jet implemented"
  end
  
end
