class CategoriesController < ApplicationController

  before_filter :load_category, :only => [:show, :upload_sheetcells, :update_sheetcells]

  skip_before_filter :deny_access_to_all

  access_control do
    actions :show do
      allow logged_in
    end
    actions :upload_sheetcells, :update_sheetcells do
      allow :admin
    end
  end

  def show
    respond_to do |format|
      format.html do
        @sheetcells = @category.sheetcells.includes(:datacolumn => :dataset).
                          select("import_value, datacolumn_id, count(*) as count").
                          group("import_value, datacolumn_id").
                          order("count desc")
      end
      format.csv do
        send_data render_sheetcells_csv, :type => "text/csv", :filename=>"#{@category.short}_sheetcells.csv", :disposition => 'attachment'
      end
    end
  end

  def upload_sheetcells
  end

  def update_sheetcells
    if !params[:csvfile] then
      flash[:error] = "No File given"
      redirect_to :back and return
    end
    f = params[:csvfile][:file].path

    @changes = @category.update_sheetcells_with_csv(f, current_user)

    unless @category.errors.empty?
      flash[:error] = @category.errors.full_messages.to_sentence
      redirect_to :back and return
    else
      flash[:notice] = "Sheetcells successfully updated"
      flash[:updates] = @changes
      redirect_to category_path @category
    end
  end

private

  def render_sheetcells_csv
    csv_string = CSV.generate do |csv|
      csv << ["ID","IMPORT VALUE","COLUMNHEADER","DATASET","NEW CATEGORY SHORT"]
      @category.sheetcells.each do |s|
        csv << [s.id, s.import_value, s.datacolumn.columnheader, s.datacolumn.dataset.title]
      end
    end
  end

  def load_category
    @category = Category.find(params[:id])
  end

end
