class ContextFreeprojectsController < ApplicationController
  # GET /context_freeprojects
  # GET /context_freeprojects.xml
  def index
    @context_freeprojects = ContextFreeproject.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @context_freeprojects }
    end
  end

  # GET /context_freeprojects/1
  # GET /context_freeprojects/1.xml
  def show
    @context_freeproject = ContextFreeproject.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @context_freeproject }
    end
  end

  # GET /context_freeprojects/new
  # GET /context_freeprojects/new.xml
  def new
    @context_freeproject = ContextFreeproject.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @context_freeproject }
    end
  end

  # GET /context_freeprojects/1/edit
  def edit
    @context_freeproject = ContextFreeproject.find(params[:id])
  end

  # POST /context_freeprojects
  # POST /context_freeprojects.xml
  def create
    @context_freeproject = ContextFreeproject.new(params[:context_freeproject])

    respond_to do |format|
      if @context_freeproject.save
        flash[:notice] = 'ContextFreeproject was successfully created.'
        format.html { redirect_to(@context_freeproject) }
        format.xml  { render :xml => @context_freeproject, :status => :created, :location => @context_freeproject }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @context_freeproject.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /context_freeprojects/1
  # PUT /context_freeprojects/1.xml
  def update
    @context_freeproject = ContextFreeproject.find(params[:id])

    respond_to do |format|
      if @context_freeproject.update_attributes(params[:context_freeproject])
        flash[:notice] = 'ContextFreeproject was successfully updated.'
        format.html { redirect_to(@context_freeproject) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @context_freeproject.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /context_freeprojects/1
  # DELETE /context_freeprojects/1.xml
  def destroy
    @context_freeproject = ContextFreeproject.find(params[:id])
    @context_freeproject.destroy

    respond_to do |format|
      format.html { redirect_to(context_freeprojects_url) }
      format.xml  { head :ok }
    end
  end
end
