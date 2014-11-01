class CategoriesController < ApplicationController
  before_filter :load_datagroup, :only => [:index, :new, :create]
  before_filter :load_category, :only => [:show, :destroy, :upload_sheetcells, :update_sheetcells]

  skip_before_filter :deny_access_to_all

  access_control do
    actions :show, :index, :new, :create, :destroy do
      allow logged_in
    end
    actions :upload_sheetcells, :update_sheetcells do
      allow :admin
    end
  end

  def index
    respond_to do |format|
      format.csv {
        send_data render_categories_csv, :type => "text/csv", :filename=>"#{@datagroup.title}_categories.csv", :disposition => 'attachment'
      }
      format.js do
        validate_sort_params(collection: ['short', 'long', 'description', 'count'], default: 'short')
        @categories = @datagroup.categories
          .select('id, short, long, description, (select count(sheetcells.id) from sheetcells where sheetcells.category_id = categories.id) as count')
          .search(params[:search])
          .order("#{params[:sort]} #{params[:direction]}")
          .paginate(page: params[:page], per_page: 20)
      end
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

  def new
  end

  def create
    @category = @datagroup.categories.build(params[:category])
    respond_to do |format|
      format.json do
        unless @datagroup.categories.exists?(['short iLike :s OR long iLike :s', s: @category.short])
          @category.save
          render :json => @category.attributes.merge(count: @datagroup.categories.count)
        else
          render :json => {error: "#{@category.short} is already taken!", count: @datagroup.categories.count}
        end
      end
    end
  end

  def destroy
    respond_to do |format|
      format.json {
        if @category.destroy
          render :json => {id: @category.id, count: @category.datagroup.categories(true).count}
        else
          render :json => {error: @category.errors.full_messages.to_sentence}
        end
      }
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

    changes = @category.update_sheetcells_with_csv(f, current_user)

    unless @category.errors.empty?
      flash[:error] = @category.errors.full_messages.to_sentence
      redirect_to :back and return
    else
      flash[:notice] = "Sheetcells successfully updated. See change list below."
      flash[:updates] = changes
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

  def render_categories_csv
    CSV.generate do |csv|
      csv << ["ID","SHORT","LONG","DESCRIPTION","MERGE ID"]
      @datagroup.categories.select([:id, :short, :long, :description]).order(:short).each do |cat|
        csv << [cat.id, cat.short, cat.long, cat.description]
      end
    end
  end

  def load_datagroup
    @datagroup = Datagroup.find(params[:datagroup_id])
  end

  def load_category
    @category = Category.find(params[:id])
  end

end
