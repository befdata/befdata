require 'test_helper'

class PaperproposalTest < ActiveSupport::TestCase

  test "any paperproposal can have one project linked" do
    paperproposal = paperproposals("paperproposals_001")
    assert paperproposal.authored_by_project
  end

  test "calculating authorship works" do
    #moved from specs here (was only one anyway)
    paperproposal = Paperproposal.find(2)
    author = User.find(6)
    senior = User.find(4)
    corresponding = author
    paperproposal_stranger = User.find(5)

    assert paperproposal.calc_authorship(author) == "Author"
    assert paperproposal.calc_authorship(senior) == "Senior author"
    assert paperproposal.calc_authorship(corresponding) != "Corresponding author"
    assert paperproposal.calc_authorship(paperproposal_stranger) == nil

  end

end
