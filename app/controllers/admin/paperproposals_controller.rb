class Admin::PaperproposalsController < Admin::AdminController
  active_scaffold :paperproposal do |config|

    [config.list, config.show].each do |c|
      c.columns = [:id, :title, :created_at]
    end
    config.show.columns << :freeformats
    config.update.columns = [:title]
  end
end