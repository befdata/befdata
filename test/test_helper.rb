# Adds code coverage analysis on test runs - and produces the nice README badge
require 'coveralls'
Coveralls.wear!('rails')

ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'authlogic/test_case'

class ActiveSupport::TestCase
  include ActionDispatch::TestProcess
  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  fixtures :all

  # make_sure_pg_functions_are_in_db this is needed for teamcity to have non_schema_sql
  %x[rake db:load_non_schema_sql]

  # Add more helper methods to be used by all tests here...

  def login_nadrowski
    nadrowski = User.find_by_login 'nadrowski'
    UserSession.create(nadrowski)
    nadrowski
  end

  def login_and_load_paperproposal(user, title)
    login_user user
    @paperproposal = Paperproposal.find_by_title(title)
  end

  def login_user(user)
    user = User.find_by_login user
    UserSession.create(user)
  end

  def test_file_for_upload(filename)
    # make Rack::Test::UploadedFile behaves like ActionDispatch::Http::UploadedFile by exposing tempfile accessor
    # please put all files for uploading under 'test_file_for_uploads' directory
    # used only for uploading files through form in functional or integration test
    fixture_file_upload(File.join('test_files_for_uploads', filename))
   end

  def login_and_load_category (user = "nadrowski", long = "Mahonia bealei")
    login_user user
    @category = Category.find_by_long long
  end

  def assert_success_no_error
    assert :success
    assert_nil flash[:error]
  end

end
