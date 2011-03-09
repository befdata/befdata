class ContextFreepeopleController < ApplicationController
  # GET /context_freepeople
  # GET /context_freepeople.xml
  def index
    @context_freepeople = ContextFreeperson.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @context_freepeople }
    end
  end

  # GET /context_freepeople/1
  # GET /context_freepeople/1.xml
  def show
    @context_freeperson = ContextFreeperson.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @context_freeperson }
    end
  end

  # GET /context_freepeople/new
  # GET /context_freepeople/new.xml
  def new
    @context_freeperson = ContextFreeperson.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @context_freeperson }
    end
  end

  # GET /context_freepeople/1/edit
  def edit
    @context_freeperson = ContextFreeperson.find(params[:id])
  end

  # POST /context_freepeople
  # POST /context_freepeople.xml
  def create
    @context_freeperson = ContextFreeperson.new(params[:context_freeperson])

    respond_to do |format|
      if @context_freeperson.save
        flash[:notice] = 'ContextFreeperson was successfully created.'
        format.html { redirect_to(@context_freeperson) }
        format.xml  { render :xml => @context_freeperson, :status => :created, :location => @context_freeperson }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @context_freeperson.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /context_freepeople/1
  # PUT /context_freepeople/1.xml
  def update
    @context_freeperson = ContextFreeperson.find(params[:id])

    respond_to do |format|
      if @context_freeperson.update_attributes(params[:context_freeperson])
        flash[:notice] = 'ContextFreeperson was successfully updated.'
        format.html { redirect_to(@context_freeperson) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @context_freeperson.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /context_freepeople/1
  # DELETE /context_freepeople/1.xml
  def destroy
    @context_freeperson = ContextFreeperson.find(params[:id])
    @context_freeperson.destroy

    respond_to do |format|
      format.html { redirect_to(context_freepeople_url) }
      format.xml  { head :ok }
    end
  end
end
