class FreeformatsController < ApplicationController

  before_filter :load_freeformat_and_dataset, :except => :create
  before_filter :load_dataset_from_params, :only => :create

  skip_before_filter :deny_access_to_all

  access_control do
    actions :download, :update, :create, :destroy do
      allow :admin
      allow :owner, :of => :dataset
      allow :proposer, :of => :dataset
    end

    actions :download do
      allow logged_in, :if => :dataset_is_free_for_members
      allow all, :if => :dataset_is_free_for_public
    end
  end

  def create
    freeformat = Freeformat.create (params[:freeformat])
    freeformat.dataset = @dataset
    if freeformat.save
      redirect_to :back
    else
      flash[:error] = "#{freeformat.errors.to_a.first.capitalize}"
      redirect_to :back
    end
  end

  def update
    if @freeformat.update_attributes (params[:freeformat]) then
      redirect_to :back
    else
      flash[:error] = "#{@freeformat.errors.to_a.first.capitalize}"
      redirect_to :back
    end
  end

  def destroy
    @freeformat.destroy
    if @freeformat.destroyed?
      redirect_to :back
    else
      flash[:error] = "#{@freeformat.errors.to_a.first.capitalize}"
      redirect_to :back
    end
  end

  def download
    send_file @freeformat.file.path
  end

  private

  def load_freeformat_and_dataset
    @freeformat = Freeformat.find params[:id]
    @dataset = @freeformat.dataset
  end

  def load_dataset_from_params
    @dataset = Dataset.find params[:dataset_id]
  end

end