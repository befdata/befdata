class Settings::DatasetsController < Admin::DatasetsController
  skip_before_filter :admin_only_acl
  before_filter :find_dataset

  access_control do
    allow :admin
    allow :owner, :of => :dataset
    allow :proposer, :of => :dataset
  end

  active_scaffold :dataset do |config|
    config.actions.exclude :delete, :search, :create
  end

private
  def find_dataset
    dataset = Dataset.find(active_scaffold_session_storage[:constraints][:id])
  end

end