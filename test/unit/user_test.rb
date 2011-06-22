require 'test_helper'

class UserTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "create user without login should not work" do
    user = User.new
    assert !user.save
  end

  test "create user and add avatar to it" do
    @user = User.new
    @user.avatar = sample_avatar
    @user.lastname = "testlastname"
    assert @user.avatar_file_name != "bla"
  end
end
