class FreeformatsController < ApplicationController

  before_filter :load_freeformat_and_freeformattable, :except => :create
  before_filter :load_freeformattable, :only => :create
  after_filter  :dataset_edit_message, :except => [:download]

  skip_before_filter :deny_access_to_all

  access_control do
    actions :download, :update, :create, :destroy do
      allow :admin
      allow :owner, :of => :dataset
      allow logged_in, :if => :paperproposal_author
    end
    actions :download do
      allow :proposer, :of => :dataset
      allow logged_in, :if => :dataset_is_free_for_project_of_user
      allow logged_in, :if => :dataset_is_free_for_members
      allow all, :if => :dataset_is_free_for_public
      allow logged_in, :if => :freeformattable_is_paperproposal
    end
  end

  def create
    freeformat = @freeformattable.freeformats.build(params[:freeformat])
    if freeformat.save
      redirect_to :back
    else
      flash[:error] = "#{freeformat.errors.to_a.first.capitalize}"
      redirect_to :back
    end
  end

  def update
    if @freeformat.update_attributes(params[:freeformat]) then
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
    send_file @freeformat.file.path, :filename=>@freeformat.to_label, :disposition => 'attachment'
  end

private
  def load_freeformattable
    @freeformattable = params[:freeformattable_type].classify.constantize.find(params[:freeformattable_id])
    load_type_of_freeformattable
  end

  def load_freeformat_and_freeformattable
    @freeformat = Freeformat.find params[:id]
    @freeformattable = @freeformat.freeformattable
    load_type_of_freeformattable
  end

  def load_type_of_freeformattable
    @dataset = @freeformattable if @freeformattable.kind_of? Dataset
    @paperproposal = @freeformattable if @freeformattable.kind_of? Paperproposal
  end

  def freeformattable_is_paperproposal
    defined? @paperproposal
  end

  def paperproposal_author
    @paperproposal && @paperproposal.author == current_user
  end

  def dataset_edit_message
    if @freeformattable.is_a? Dataset
      @freeformattable.log_edit('Files changed')
    end
  end

end
