require 'test_helper'

class PaperproposalTest < ActiveSupport::TestCase

  test "any paperproposal can have one project linked" do
    paperproposal = paperproposals("Paperproposals_001")
    assert paperproposal.project
  end


end
