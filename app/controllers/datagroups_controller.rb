require 'csv'

class DatagroupsController < ApplicationController

  before_filter :load_datagroup, :only => [:show, :upload_categories, :update_categories, :edit, :update, :destroy, :datacolumns]

  skip_before_filter :deny_access_to_all
  access_control do
    actions :index, :show do
      allow logged_in
    end
    actions :upload_categories, :update_categories, :edit, :update, :destroy, :datacolumns do
      allow :admin
    end
  end

  def index
    @datagroups = Datagroup.order(:title)
  end

  def show
    set_sort_params
    @categories = @datagroup.categories.joins('left join sheetcells on categories.id = sheetcells.category_id').
        select('categories.*, count(sheetcells.id) as count').group('categories.id').search(params[:search]).
        paginate(
          page: params[:page],
          per_page: 20,
          order: "#{params[:sort]} #{params[:direction]}"
        )

    respond_to do |format|
      format.html
      format.js
      format.csv do
        send_data render_categories_csv, :type => "text/csv", :filename=>"#{@datagroup.title}_categories.csv", :disposition => 'attachment'
      end
    end
  end

  def update
    if @datagroup.update_attributes(params[:datagroup])
      redirect_to @datagroup, notice: "Successfully updated"
    else
      render :edit
    end
  end

  def destroy
    unless @datagroup.datasets.empty?
      flash[:error] = "Datagroup has associated datasets and cann't be deleted"
      redirect_to :back
    end
    if @datagroup.destroy
      redirect_to datagroups_path, :notice => "Deleted #{@datagroup.title}"
    else
      flash[:error] = @datagroup.errors.full_messages.to_sentence
      redirect_to :back
    end
  end

  # step 1 to batch update datagroup categories via CSV
  def upload_categories
  end

  # step 2 to batch update datagroup categories via CSV
  def update_categories
    if !params[:csvfile] then
      flash[:error] = "No File given"
      redirect_to :back and return
    end
    f = params[:csvfile][:file].tempfile

    @changes = @datagroup.update_categories_with_csv(f, current_user)

    unless @datagroup.errors.empty?
      flash[:error] = @datagroup.errors.full_messages.to_sentence
      redirect_to :back and return
    else
      flash[:notice] = "Categories successfully updated"
      flash[:updates] = @changes
      redirect_to datagroup_path @datagroup
    end
  end

  def datacolumns
    @datacolumns = @datagroup.datacolumns.paginate(:page => params[:page], :per_page => 20, :order => "columnheader")
  end

  private

  def render_categories_csv
    csv_string = CSV.generate do |csv|
      csv << ["ID","SHORT","LONG","DESCRIPTION","MERGE ID"]
      @datagroup.categories.sort_by(&:short).each do |cat|
        csv << [cat.id, cat.short, cat.long, cat.description]
      end
    end
  end

  def load_datagroup
    @datagroup = Datagroup.find(params[:id])
  end

  def set_sort_params(default= "short asc")
    column, direction = default.split
    params[:sort] ||= column
    params[:direction] ||= direction
  end

end
