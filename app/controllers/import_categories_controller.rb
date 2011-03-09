class ImportCategoriesController < ApplicationController
  # GET /import_categories
  # GET /import_categories.xml
  def index
    @import_categories = ImportCategory.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @import_categories }
    end
  end

  # GET /import_categories/1
  # GET /import_categories/1.xml
  def show
    @import_category = ImportCategory.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @import_category }
    end
  end

  # GET /import_categories/new
  # GET /import_categories/new.xml
  def new
    @import_category = ImportCategory.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @import_category }
    end
  end

  # GET /import_categories/1/edit
  def edit
    @import_category = ImportCategory.find(params[:id])
  end

  # POST /import_categories
  # POST /import_categories.xml
  def create
    @import_category = ImportCategory.new(params[:import_category])

    respond_to do |format|
      if @import_category.save
        flash[:notice] = 'ImportCategory was successfully created.'
        format.html { redirect_to(@import_category) }
        format.xml  { render :xml => @import_category, :status => :created, :location => @import_category }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @import_category.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /import_categories/1
  # PUT /import_categories/1.xml
  def update
    @import_category = ImportCategory.find(params[:id])

    respond_to do |format|
      if @import_category.update_attributes(params[:import_category])
        flash[:notice] = 'ImportCategory was successfully updated.'
        format.html { redirect_to(@import_category) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @import_category.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /import_categories/1
  # DELETE /import_categories/1.xml
  def destroy
    @import_category = ImportCategory.find(params[:id])
    @import_category.destroy

    respond_to do |format|
      format.html { redirect_to(import_categories_url) }
      format.xml  { head :ok }
    end
  end
end
