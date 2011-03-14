# This file controlls the import of an BEF-China workbook into the
# data portal.  It opens the file uploaded to the data portal and
# stores it's values in the data base.  It then goes through data and
# metadata interactively to verify the correctness of the data.  For
# opening the workbook we currently rely on the ruby-package
# "spreadsheet".  This has to be changed here to adapt to other
# formats such as Open Office or .xlsx files.

#require 'spreadsheet'

class ImportsController < ApplicationController


  def create_dataset_filevalue
      filevalue = Filevalue.new(params[:filevalue])

      begin
        Filevalue.transaction do
          filevalue.save
          #TODO should go the context upload action
          redirect_to(:controller => :datasets, :action => :upload,
                      :filevalue_id => filevalue.id)
        end
      rescue ActiveRecord::RecordInvalid => invalid
        redirect_to :back
        #TODO showing the message that file upload did not work
      end
  end

end
