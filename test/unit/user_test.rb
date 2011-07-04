require 'test_helper'

class UserTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "create user without login should not work" do
    user = User.new
    assert !user.save
  end

  test "add avatar to user" do
    @user = User.find_by_login 'nadrowski'
    @user.avatar = sample_avatar
    @user.save
    expected_avatar_file_name = "#{@user.id}_#{@user.lastname}#{File.extname(sample_avatar).downcase}"
    assert @user.avatar_file_name == expected_avatar_file_name
  end
end
