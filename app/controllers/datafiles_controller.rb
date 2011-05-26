class DatafilesController < ApplicationController

  access_control do
    action :download do
      allow logged_in
    end
  end

  def download
   @file = Datafile.find(params[:id])
   send_file @file.file.path, :type => @file.file_content_type, :disposition => 'inline'
  end

end
