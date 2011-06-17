ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'authlogic/test_case'

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  fixtures :all

  # Add more helper methods to be used by all tests here...

  def login_nadrowski
    nadrowski = User.find_by_login 'nadrowski'
    UserSession.create(nadrowski)
  end

  def login_and_load_paperproposal(title)
    login_nadrowski
    @paperproposal = Paperproposal.find_by_title(title)
  end

end
