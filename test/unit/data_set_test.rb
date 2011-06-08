require 'test_helper'

class DataSetTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "any dataset can have zero to many projects linked" do
    p_datasets = projects("Projects_001").datasets
    assert p_datasets
  end
end
