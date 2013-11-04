require 'test_helper'
require 'spreadsheet'

class WorkbookTest < ActiveSupport::TestCase

  def setup
    @dataset = Dataset.find(5)
    @workbook = Workbook.new(@dataset.current_datafile)
  end

  test 'file should be a valid BEF workbook' do
    assert @workbook.valid?
  end

  test "workbook should have four column headers" do
    assert_equal 4, @workbook.headers.length
  end

  test "Authors should be recognized correcty" do
    assert_equal 1, @workbook.authors_list[:found_users].length
    assert_equal 1, @workbook.authors_list[:unfound_usernames].length

    assert_equal "Karin", @workbook.authors_list[:found_users].first.firstname
    assert_match "Verena", @workbook.authors_list[:unfound_usernames].first
  end

  test "general metadata hash should fill up correctly" do
    assert_equal 'Test species name import', @workbook.general_metadata_hash[:title]
    assert_match /Comparative Study Plots/,  @workbook.general_metadata_hash[:abstract]
    assert_match /National Forest Reserve/, @workbook.general_metadata_hash[:spatialextent]

    assert_equal Date.new(2011, 4, 18), @workbook.general_metadata_hash[:datemin]
    assert_equal Date.new(2011, 4, 18), @workbook.general_metadata_hash[:datemax]
  end

  test 'column sequence should be recognized correctly' do
    header_columnnr = @workbook.send(:header_info_lookup)
    assert_equal 0, header_columnnr['height']
    assert_equal 3, header_columnnr['fullname']
  end

  test 'columns and datagroup sheet should be read correctly' do
    columns_info = @workbook.send(:columns_info)
    column_height = columns_info.assoc('height')
    # column info
    assert_equal 'height in m', column_height[DataworkbookFormat::WBF[:column_definition_col]]
    assert_equal 'number', column_height[DataworkbookFormat::WBF[:column_methodvaluetype_col]]
    # data group info
    assert_equal 'height', column_height[DataworkbookFormat::WBF[:group_title_col]]
    assert_equal 'height in m', column_height[DataworkbookFormat::WBF[:group_description_col]]
  end
end
