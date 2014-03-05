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

  test 'update category expires exported data files' do
    category_id = 61
    dataset = Dataset.find(5)
    orig_invalidated_at_excel = dataset.exported_excel.invalidated_at
    orig_invalidated_at_csv = dataset.exported_csv.invalidated_at

    Category.find(category_id).update_attributes(:comment => "test triggers")

    assert dataset.exported_excel(true).invalidated_at > orig_invalidated_at_excel
    assert dataset.exported_csv(true).invalidated_at > orig_invalidated_at_csv

  end

end