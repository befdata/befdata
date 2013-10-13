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
    if params[:notify].blank?
      flash[:error] = "You should choose to whom the notifications are sent !"
      redirect_to :back and return
    end

    if @dataset_edit.update_attributes(params[:dataset_edit].merge({submitted: true}))
      @dataset_edit.notify(params[:notify])
      flash[:notice] = "Notifications were successfully submitted and sent, Thanks!"
    else
      flash[:error] = @dataset_edit.errors.full_messages.to_sentence
    end
    redirect_to :back
  end

private

  def load_dataset_and_its_edit
    @dataset_edit = DatasetEdit.find(params[:id])
    @dataset = @dataset_edit.dataset
  end

end