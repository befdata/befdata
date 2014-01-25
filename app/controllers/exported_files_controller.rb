class ExportedFilesController < ApplicationController
  before_filter :load_file
  skip_before_filter :deny_access_to_all

  access_control do
    actions :regenerate_download do
      allow :admin, :data_admin
      allow :owner, :proposer, :of => :dataset
      allow logged_in, :if => :dataset_is_free_for_members
      allow logged_in, :if => :dataset_is_free_for_project_of_user
      allow all, :if => :dataset_is_free_for_public
    end
  end

  def regenerate_download
    @exported_file.queued_to_be_exported
    puts download_page_dataset_path(@dataset, :anchor => @exported_file.format)
    redirect_to download_page_dataset_path(@dataset, :anchor => @exported_file.format)
  end

private
  def load_file
    @exported_file = ExportedFile.find(params[:id])
    @dataset = @exported_file.dataset
  end
end
