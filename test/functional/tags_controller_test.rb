require 'test_helper'

class TagsControllerTest < ActionController::TestCase
  test "should get show" do
    get :show, :id => ActsAsTaggableOn::Tag.first.id
    assert_success_no_error
  end

  test "should get index" do
    get :index
    assert_success_no_error
  end

  test 'merge keywords into a new one' do
    activate_authlogic
    login_nadrowski

    taggables = Datacolumn.tagged_with(['KEY_1', 'KEY_2'], any: true)

    post :merge, {keywords: [21,31], new_keyword: 'key'}
    assert_success_no_error

    assert ActsAsTaggableOn::Tag.exists?(name: 'key')
    assert_nil ActsAsTaggableOn::Tag.find_by_name('KEY_1')
    assert_nil ActsAsTaggableOn::Tag.find_by_name('KEY_2')

    assert taggables.all?{|tg| tg.tag_list.include?('key') && (tag.tag_list & ['KEY_1', 'KEY_2']).empty? }
  end

  test "merge keywords into an existing one" do
    activate_authlogic
    login_nadrowski

    taggables = Datacolumn.tagged_with(['KEY_1', 'KEY_2'], any: true)

    post :merge, {keywords: [21,31], merge_to: '21'} # merge to KEY_1
    assert_success_no_error

    assert_nil ActsAsTaggableOn::Tag.find_by_name('KEY_2')

    assert taggables.all?{|tg| tg.tag_list.include?('KEY_1') && tg.tag_list.exclude?('KEY_2') }
  end

end
