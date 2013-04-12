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

    pending "havn't test edited calc_authorship method"
  end

  test "expired download rights are removed" do
    old_roles_count = Role.count
    Paperproposal.find(7).update_attribute(:expiry_date, Date.yesterday)
    Paperproposal.revoke_old_download_rights
    assert old_roles_count > Role.count
  end

end
