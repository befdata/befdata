require 'test_helper'

class UsersHelperTest < ActionView::TestCase
  def sample_avatar(filename = "test_avatar.png")
    File.new("test/test files for upload/#{filename}")
  end
end
