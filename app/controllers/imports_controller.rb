# This file controlls the import of an BEF-China workbook into the
# data portal.  It opens the file uploaded to the data portal and
# stores it's values in the data base.  It then goes through data and
# metadata interactively to verify the correctness of the data.  For
# opening the workbook we currently rely on the ruby-package
# "spreadsheet".  This has to be changed here to adapt to other
# formats such as Open Office or .xlsx files.

class ImportsController < ApplicationController
  before_filter :load_freeformats_dataset, :only => [:update_dataset_freeformat_file]

  skip_before_filter :deny_access_to_all
  access_control do
    #TODO this has to be specified see #
    allow logged_in

    action :update_dataset_freeformat_file do
      allow :owner, :of => :freeformats_dataset
    end
  end

  def create_dataset_freeformat
    freeformat = Freeformat.new(params[:freeformat])

    if freeformat.save
      redirect_to :controller => :datasets, :action => :upload_dataset_freeformat, :freeformat_id => freeformat.id
    else
      flash[:error] = "#{freeformat.errors.to_a.first.capitalize}"
      redirect_to :back
    end
  end

  def update_dataset_freeformat_file
    freeformat = Freeformat.find(params[:freeformat][:id])
    freeformat.file = params[:freeformat][:file]
    if freeformat.save
      redirect_to :controller => :datasets, :action => :show, :id => freeformat.dataset.id
    else
      flash[:error] = "#{freeformat.errors.to_a.first.capitalize}"
      redirect_to :back
    end
  
  end

  def dataset_freeformat_overview

    @dataset = Dataset.find(params[:dataset_id])

    if @dataset
      # nothing to be done
    else
      # really should tell them about the error
      redirect_to data_path and return
    end

  end

  def save_dataset_freeformat_tags

    @dataset = Dataset.find(params[:dataset][:id])
    @dataset.update_attributes(params[:dataset])

    redirect_to url_for(:controller => :datasets,
    :action => :show,
    :id => @dataset.id) and return
  end

  private

  def load_workbook
    @book = Dataworkbook.new(@dataset.upload_spreadsheet)
  end

  def load_freeformats_dataset
    @freeformats_dataset = Freeformat.find(params[:freeformat][:id]).dataset
  end

end
