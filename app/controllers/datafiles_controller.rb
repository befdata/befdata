class DatafilesController < ApplicationController

  skip_before_filter :deny_access_to_all
  before_filter :load_dataset_and_datafile
  access_control do
    action :download, :destroy do
      allow :admin
      allow :owner, :of => :dataset
    end
  end

  def download
    send_file @datafile.file.path
  end

  def destroy
    flash[:error] = @datafile.errors.full_messages.to_sentence unless @datafile.destroy
    redirect_to :back
  end

private
  def load_dataset_and_datafile
    @dataset = Dataset.find(params[:dataset_id])
    @datafile = @dataset.upload_spreadsheets.find(params[:id])
  end
end
