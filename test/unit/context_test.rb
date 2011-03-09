require 'test_helper'

class ContextTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "should have a context" do
    context = Context.find_by_id("1")
    assert context.valid?
  end
end
