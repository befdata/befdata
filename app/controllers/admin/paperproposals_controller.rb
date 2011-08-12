class Admin::PaperproposalsController < Admin::AdminController
  active_scaffold :paperproposal do |config|
    config.show.columns = [:created_at]

    config.columns = [:id, :title, :created_at]

    [config.update].each do |c|
      c.columns = [:title, :created_at]
    end
  end
end