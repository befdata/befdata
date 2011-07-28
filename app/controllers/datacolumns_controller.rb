class DatacolumnsController < ApplicationController

  # ACL9 access block for the methods of this controller.
  skip_before_filter :deny_access_to_all
  access_control do
    actions :edit, :update_datagroup, :update_datatype, :update_people do
      allow :admin
      allow :owner, :of => :dataset
      allow :proposer, :of => :dataset
    end
  end

  # This method provides als neccessary informations
  # for the display of the Data Column approval pages.
  def edit
    # Unless we know more, we're in the first step,
    @step = 'one'
    
    # Get the central Data Column object from the database.
    @data_column ||= Datacolumn.find(params[:id])

    # We're working with the Data Workbook, too. Thus, we must load it.
    @book = Dataworkbook.new(@data_column.dataset.upload_spreadsheet)

    # We extract the column header to determine the available Data Groups from the Data Workbook.
    columnheader = @data_column.columnheader
    data_group_title = @book.method_index_for_columnheader(columnheader).blank? ? columnheader : @book.data_group_title(columnheader)
    @data_groups_available = Datagroup.find_similar_by_title(data_group_title)

    # Is the Data Group of this Data Column approved? If no, then render the Data Group approval partial. That's called step 1.
    unless @data_column.datagroup_approved?
      render :partial => 'approve_datagroup' and return
    end

    # Is the Data Type of this Data Column approved? If no, then render the Data Type approval partial. That's called step 2.
    unless @data_column.datatype_approved?
      @step = 'two'
      render :partial => 'approve_datatype' and return
    end

    @step = 'three'
    @dataset = @data_column.dataset
    @cats_to_choose = @data_column.datagroup.datacell_categories
    @cell_uniq_arr = @data_column.invalid_values

    # Collect all methods for the select tag.
    @methods_short_list = Datagroup.find(:all, :order => "title").collect{|m| [m.title, m.id]}

    # Prepare a new data group instance to save it if needed. Still needed? don't think so.
    @data_group_new = Datagroup.new(@book.methodsheet_datagroup(columnheader))

    # Gather the list of all Person Roles, sorted by their last name.
    @people_list = User.find(:all, :order => :lastname)

    # Collect the already linked people.
    @ppl = @data_column.users
  
    # Look into the spreadsheet, when there are no people linked.
    if @ppl.blank?
      # Look for people in the Data Workbook and link them to the Data Group.
      ppl = @book.lookup_data_header_people(columnheader)
      ppl = ppl.flatten.uniq
      ppl.each do |user|
        user.has_role! :responsible, @data_column
      end
      @ppl = @data_column.users
    end
    @step = 'five'
    render :layout => false
  end

  def show
  end

  def update_datagroup
    @data_column = Datacolumn.find(params[:id])
    unless params[:datagroup] == '-1'
      @data_group = Datagroup.find(params[:datagroup])
      @data_column.datagroup = @data_group
      @data_column.datagroup_approved = true
      @data_column.save
      flash[:notice] = "Data Group successfully saved. Data Column #{@data_column.columnheader} was marked as approved."
      redirect_to :back
    else
      begin
        @data_group = Datagroup.new(params[:new_datagroup])
        Datacolumn.transaction do
          if @data_group.save
            @data_column.datagroup = @data_group
            @data_column.datagroup_approved = true
            @data_column.save
            flash[:notice] = "Data Group successfully saved. Data Column #{@data_column.columnheader} was marked as approved."
            redirect_to :back
          else
            flash[:error] = "#{@data_group.errors.to_a.first.capitalize}"
            redirect_to :back
          end
        end
      rescue ActiveRecord::RecordInvalid => invalid
        redirect_to :back
      end
    end
  end

  # Assingning provenance informaiton: linking people to a data column
  def update_people
    @data_column = Datacolumn.find(params[:id])
      
    new_people = params[:people] ||= []
    @data_column.users.each{|u| u.has_no_role! :responsible, @data_column unless new_people.include?(u.id.to_s)}
    new_people.each{|p| User.find(p).has_role! :responsible, @data_column unless @data_column.users.include?(User.find(p))}
    
    # When the comment field was actually changed, we need to save this.
    unless @data_column.comment == params[:comment]
      @data_column.comment = params[:comment]
      @data_column.save
    end
    
    redirect_to :back
  end

  def update_datatype
    @data_column = Datacolumn.find(params[:id])
    @data_column.update_attributes(params[:datacolumn])

    @data_column.add_data_values
    @data_column.datatype_approved = true
    @data_column.save
    redirect_to :back
  end
end
