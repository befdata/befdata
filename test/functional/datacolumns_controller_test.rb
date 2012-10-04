require 'test_helper'

class DatacolumnsControllerTest < ActionController::TestCase
  setup :activate_authlogic

  # because the update of a datacolumns datatype in test "update datagroup" calls some
  # sql statement in Datacolumn.add_data_values(user) which is conflicting with the dafault rails test transactions
  self.use_transactional_fixtures = false

  test "show approval overview" do
    login_nadrowski

    get :approval_overview, :id => 61

    assert_success_no_error
  end

  test "next approval step redirects" do
    login_nadrowski

    get :next_approval_step, :id => 61

    assert_redirected_to approval_overview_datacolumn_url(61)
    assert_success_no_error
  end

  test "show approve datagroup" do
    login_nadrowski

    get :approve_datagroup, :id => 61

    assert_success_no_error
  end

  test "show approve datatype" do
    login_nadrowski

    get :approve_datatype, :id => 61

    assert_success_no_error
  end

  test "show approve invalid values" do
    login_nadrowski

    get :approve_invalid_values, :id => 61

    assert_success_no_error
  end

  test "show approve metadata" do
    login_nadrowski

    get :approve_metadata, :id => 61

    assert_success_no_error
  end

  test "create and assign new datagroup" do
    login_nadrowski
    datacolumn_id = 61

    post :create_and_update_datagroup,
         {:id => datacolumn_id, :new_datagroup => {:title => 'test datagroup', :description => 'test description'}}

    assert_success_no_error
    assert_equal 'test datagroup', Datacolumn.find(datacolumn_id).datagroup.title
  end

  test "update datagroup" do
    login_nadrowski
    datacolumn_id = 61

    post :update_datagroup, :id => datacolumn_id, :datagroup => 32

    assert_success_no_error
    assert_equal 'Aspect', Datacolumn.find(datacolumn_id).datagroup.title
  end

  test "update datatype" do
    login_nadrowski
    datacolumn_id = 61

    post :update_datatype, :id => datacolumn_id, :import_data_type => 'category'

    assert_success_no_error
    assert_equal 'category', Datacolumn.find(datacolumn_id).import_data_type
  end

  test "update metadata" do
    login_nadrowski
    datacolumn_id = 61

    post :update_metadata, :id => datacolumn_id,
         :datacolumn => {:definition => 'test definition'}

    assert_success_no_error
    assert_equal 'test definition', Datacolumn.find(datacolumn_id).definition
  end

  test "update invalid values" do
    login_nadrowski
    datacolumn_id = 64

    post :update_invalid_values, :id => datacolumn_id,
         :short_value_0 => 'x', :long_value_0 => 'xx', :description_0 => 'xxx'

    assert_success_no_error
    cat = Category.find_by_short('x')
    sc_cats = Datacolumn.find(datacolumn_id).sheetcells.map{|s| s.category}
    assert_include sc_cats, cat
  end

end