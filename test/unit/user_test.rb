require 'test_helper'

class UserTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "create user without login should not work" do
    user = User.new
    assert !user.save
  end
end
