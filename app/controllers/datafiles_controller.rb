class DatafilesController < ApplicationController

  skip_before_filter :deny_access_to_all
  access_control do
    action :download do
      allow logged_in
    end
  end

  def download
   @file = Datafile.find(params[:id])
   send_file @file.file.path
  end

end
