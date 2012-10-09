require 'test_helper'

class ApprovalProcessForDatacolumnTest < ActionDispatch::IntegrationTest
  fixtures :all
  self.use_transactional_fixtures = false #for datatyoe approval


  # mainly checks the approval process and sheetcell status
  test "completely approve a datacolumn" do
    @user = User.find_by_login('nadrowski')
    @datacolumn = Datacolumn.find 33

    ## login
    post user_session_path, {:user_session=>{:login=>@user.login, :password=>"test"}}

    ## get first approval step
    get next_approval_step_datacolumn_url @datacolumn
    # be redirected to group approval
    assert_redirected_to approve_datagroup_datacolumn_url @datacolumn
    assert_success_no_error

    ## create and assign new datagroup
    post create_and_update_datagroup_datacolumn_url @datacolumn,
        :new_datagroup => {:title => 'some test datagroup', :description => 'test description'}
    # be redirected to datatype approval
    assert_redirected_to approve_datatype_datacolumn_url @datacolumn
    assert_success_no_error

    ## assign datatype
    post update_datatype_datacolumn_url @datacolumn, :import_data_type => 'number'
    # be redirected to invalid values
    assert_redirected_to approve_invalid_values_datacolumn_url @datacolumn
    assert_success_no_error
    # check sheetcells
    @datacolumn.reload
    assert_equal 1, @datacolumn.sheetcells.where(:status_id => Sheetcellstatus::INVALID).count
    assert_equal 3, @datacolumn.sheetcells.where(:status_id => Sheetcellstatus::VALID).count

    ## approve invalid values
    post update_invalid_values_datacolumn_url @datacolumn,
         :short_value_0 => 'na', :long_value_0 => 'nana', :description_0 => 'nanana'
    # be redirected to metadata
    assert_redirected_to approve_metadata_datacolumn_url @datacolumn
    assert_success_no_error
    # check sheetcell status
    assert_equal 4, @datacolumn.sheetcells.where(:status_id => Sheetcellstatus::VALID).count

    ## approve metadata
    post update_metadata_datacolumn_url @datacolumn,
         :datacolumn => {:definition => 'test definition'}
    assert_redirected_to approval_overview_datacolumn_url @datacolumn
    assert_success_no_error # be redirected to overview
  end
end
