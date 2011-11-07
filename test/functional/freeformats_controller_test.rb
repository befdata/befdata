require 'test_helper'

class FreeformatsControllerTest < ActionController::TestCase
  setup :activate_authlogic

  test "download freeformat file should work" do
    login_nadrowski

    get :download, :id => Freeformat.first

    assert :success
  end

  test "add freeformat to dataset and change it and delete it" do
    login_nadrowski
    dataset = Dataset.first
    f = File.new(File.join(fixture_path, 'test_files_for_uploads', 'empty_test_file.txt'))
    request.env["HTTP_REFERER"] = edit_dataset_path dataset

    post :create, :freeformat => {:file => f}, :freeformattable_id => dataset.id, :freeformattable_type => dataset.class.to_s

    assert !dataset.freeformats.select{|ff| ff.file_file_name == 'empty_test_file.txt'}.empty?

    #and now change it...
    freeformat = dataset.freeformats.select{|ff| ff.file_file_name == 'empty_test_file.txt'}.first
    f =  File.new(File.join(fixture_path, 'test_files_for_uploads', 'empty_freeformat_file.ppt'))

    put :update, :id => freeformat.id, :freeformat => {:file => f}

    assert Freeformat.find(freeformat.id).file_file_name == 'empty_freeformat_file.ppt'
    assert_empty Freeformat.select{|ff| ff.file_file_name =='empty_test_file.txt'}

    #now delete it
    get :destroy, :id => freeformat.id

    assert !Freeformat.exists?(freeformat.id)
  end

  test "freeformat download error message if inappropriate rights" do
    ds = Dataset.find_by_title "Unit tests"
    f = ds.freeformats.first
    user = User.find_by_login "pinutrientcycling"

    login_user user.login
    @request.env['HTTP_REFERER'] = login_url

    assert ds.freeformats.count > 0
    assert !user.has_roles_for?(ds) && !user.has_role?(:admin)

    get :download, :id => f.id
    assert_match /.*Access denied.*/, flash[:error]
  end

  test "freeformat download redirect to login if not for public" do
    ds = Dataset.find_by_title "Unit tests"
    f = ds.freeformats.first
    get :download, :id => f.id

    assert_redirected_to login_url
    assert_match /.*Access denied.*/, flash[:error]
  end
end