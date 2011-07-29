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

  def login_and_load_paperproposal(user, title)
    login_user user
    @paperproposal = Paperproposal.find_by_title(title)
  end

  def login_user(user)
    user = User.find_by_login user
    UserSession.create(user)
  end

  def sample_avatar(filename = "test-avatar.png")
    File.new(File.join(fixture_path, 'test_files_for_uploads', filename))
  end

  def login_and_load_category (user = "nadrowski", long = "Mahonia bealei")
    login_user user
    @category = Category.find_by_long long
  end

  def non_admin_users
    User.all - User.joins(:role_objects).where("roles.name" => "admin")
  end

  def dataset_owners
    User.joins(:role_objects).where("roles.authorizable_type" => :Dataset, "roles.name" => :owner).uniq
  end

  def find_user_datasets_with_role (user = dataset_owners.first, role_name = :owner)
    Dataset.all.select {|d| d.accepts_role?(role_name, user)}
  end

end
