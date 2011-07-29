require 'test_helper'

class CategoryTest < ActiveSupport::TestCase

  test "creating category without short should not work" do
    c = Category.new
    assert !c.save
  end

  test "autofill missing long and description" do
    c = Category.new
    c.short = 'testshort'
    assert c.save
    assert c.long && c.description
  end

end