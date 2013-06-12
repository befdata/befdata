class DatasetEditsController < ApplicationController

  before_filter :load_dataset_and_its_edit, :only => [:submit]

  skip_before_filter :deny_access_to_all

  access_control do
    actions :index do
      allow logged_in
    end
    actions :submit do
      allow :admin
      allow :data_admin
      allow :owner, :of => :dataset
    end
  end

  def index
    @dataset = Dataset.find(params[:dataset_id])
  end

  def submit
    @dataset_edit.submitted = true
    if @dataset_edit.update_attributes(params[:dataset_edit])
      result = "Submitted to dataset edit log. "
      result << @dataset_edit.notify(params).to_s
      flash[:notice] = result
    else
      flash[:error] = @dataset_edit.errors.to_sentence
    end
    redirect_to :back
  end

private

  def load_dataset_and_its_edit
    @dataset_edit = DatasetEdit.find(params[:id])
    @dataset = @dataset_edit.dataset
  end

end