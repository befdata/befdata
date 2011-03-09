class FilevaluesController < ApplicationController

  # GET /filevalues
  # GET /filevalues.xml
  def index
    if logged_in?
      @filevalues = Filevalue.all
      
      respond_to do |format|
        format.html # index.html.erb
        format.xml  { render :xml => @filevalues }
      end
    else
      # Not logged in, redirect to login form
      session[:return_to] = request.request_uri
      redirect_to login_path and return
    end
  end

  # GET /filevalues/1
  # GET /filevalues/1.xml
  def show
    if logged_in?
      @filevalue = Filevalue.find(params[:id])
      
      respond_to do |format|
        format.html # show.html.erb
        format.xml  { render :xml => @filevalue }
      end
    else
      # Not logged in, redirect to login form
      session[:return_to] = request.request_uri
      redirect_to login_path and return
    end
  end

  # GET /filevalues/new
  # GET /filevalues/new.xml
  def new
    if logged_in?
      @filevalue = Filevalue.new

      respond_to do |format|
        format.html # new.html.erb
        format.xml  { render :xml => @filevalue }
      end
    else
      # Not logged in, redirect to login form
      session[:return_to] = request.request_uri
      redirect_to login_path and return
    end
  end

  # GET /filevalues/1/edit
  # def edit
  #   @filevalue = Filevalue.find(params[:id])
  # end

  # POST /filevalues
  # POST /filevalues.xml
  def create
    if logged_in?
      @filevalue = Filevalue.new(params[:filevalue])

      respond_to do |format|
        if @filevalue.save
          flash[:notice] = 'Filevalue was successfully created.'
          format.html { redirect_to(@filevalue) }
          format.xml  { render :xml => @filevalue, :status => :created, :location => @filevalue }
        else
          format.html { render :action => "new" }
          format.xml  { render :xml => @filevalue.errors, :status => :unprocessable_entity }
        end
      end
    else
      # Not logged in, redirect to login form
      session[:return_to] = request.request_uri
      redirect_to login_path and return
    end
  end

  # PUT /filevalues/1
  # PUT /filevalues/1.xml
  def update
    if logged_in?
      @filevalue = Filevalue.find(params[:id])

      respond_to do |format|
        if @filevalue.update_attributes(params[:filevalue])
          flash[:notice] = 'Filevalue was successfully updated.'
          format.html { redirect_to(@filevalue) }
          format.xml  { head :ok }
        else
          format.html { render :action => "edit" }
          format.xml  { render :xml => @filevalue.errors, :status => :unprocessable_entity }
        end
      end
    else
      # Not logged in, redirect to login form
      session[:return_to] = request.request_uri
      redirect_to login_path and return
    end
  end

  # DELETE /filevalues/1
  # DELETE /filevalues/1.xml
  def destroy
    if logged_in?

      @filevalue = Filevalue.find(params[:id])
      @filevalue.destroy
      
      respond_to do |format|
        format.html { redirect_to(filevalues_url) }
        format.xml  { head :ok }
      end
    else
      # Not logged in, redirect to login form
      session[:return_to] = request.request_uri
      redirect_to login_path and return
    end

  end


  def download
    if logged_in?

      @file = Filevalue.find(params[:id])
      
      send_file @file.file.path, :type => @file.file_content_type, :disposition => 'inline'
    else
      # Not logged in, redirect to login form
      session[:return_to] = request.request_uri
      redirect_to login_path and return
    end
  end
  
end
