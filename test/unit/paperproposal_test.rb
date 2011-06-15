require 'test_helper'

class PaperproposalTest < ActiveSupport::TestCase

  test "any paperproposal can have one project linked" do
    paperproposal = paperproposals("paperproposals_001")
    assert paperproposal.authored_by_project
  end


end
