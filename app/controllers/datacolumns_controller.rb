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

  # This method provides all neccessary informations
  # for the display of the Data Column approval pages.
  def edit
    # Unless we know more, we're in the first step.
    @step = 'one'
    
    # Get the central Data Column object from the database.
    @data_column ||= Datacolumn.find(params[:id])

    # We're working with the Data Workbook, too. Thus, we have to load it.
    @book = Dataworkbook.new(@data_column.dataset.upload_spreadsheet)

    # We extract the column header to determine the available Data Groups from the Data Workbook.
    columnheader = @data_column.columnheader
    data_group_title = @book.method_index_for_columnheader(columnheader).blank? ? columnheader : @book.data_group_title(columnheader)
    @data_groups_available = Datagroup.find_similar_by_title(data_group_title)

    # Is the Data Group of this Data Column approved? If no, then render the Data Group approval partial.
    unless @data_column.datagroup_approved?
      render :partial => 'approve_datagroup' and return
    end

    # Is the Data Type of this Data Column approved? If no, then render the Data Type approval partial.
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
  
  # This method is called whenever someone clicks on the 'Save Data Group' Button
  # in the Data Column approval process. 
  def update_datagroup
    # Find the Data Column.
    @data_column = Datacolumn.find(params[:id])
      
    # Whenever the datagroup parameter is '-1' this means that
    # the Data Group was not chosen bur submitted via the manual form.
    unless params[:datagroup] == '-1'
      # The datagroup parameter is not '-1'. Go find it in the Database and assign it to this Data Column.
      @data_group = Datagroup.find(params[:datagroup])
      @data_column.datagroup = @data_group
      
      # Update the datagroup approval flag and save.
      @data_column.datagroup_approved = true
      @data_column.save
      
      # Create a nice success message and redirect back so we render the same view again.
      flash[:notice] = "Data Group successfully saved. Data Column #{@data_column.columnheader} was marked as approved."
      redirect_to :back
    else
      # The datagroup parameter was '-1', hence we need to create a new Data Group.
      begin
        # Create the new Data Group and save it to the database.
        @data_group = Datagroup.new(params[:new_datagroup])
        Datacolumn.transaction do
          if @data_group.save
            # When properly saved, assign the new Data Group to this Data Column,
            # update the approval flag and save.
            @data_column.datagroup = @data_group
            @data_column.datagroup_approved = true
            @data_column.save
            
            # Generate a nice success message and redirect back so we render the same view again.
            flash[:notice] = "Data Group successfully saved. Data Column #{@data_column.columnheader} was marked as approved."
            redirect_to :back
          else
            # When saving went wrong, generate a failure message and redirect back anyway.
            flash[:error] = "#{@data_group.errors.to_a.first.capitalize}"
            redirect_to :back
          end
        end
      # This Exception is thrown by 'save' when the record-to-save could not be validated. 
      rescue ActiveRecord::RecordInvalid => invalid
        # When validation was not possible, generate a failure message and redirect back anyway. 
        flash[:error] = "#{invalid.errors.to_a.first.capitalize}"
        redirect_to :back
      end
    end
  end

  # This method is called whenever someone clicks on the 'Save People' Button
  # in the Data Column approval process.
  #
  # The people submitted via form are assigned to the Data Column or their assignation is revoked.
  def update_people
    # Find the Data Column.
    @data_column = Datacolumn.find(params[:id])
      
    # Retrieve the new list of people from the form params. 
    new_people = params[:people] ||= []
      
    # Check all currently responsible users whether they are also new people. If not, remove them. 
    @data_column.users.each{|u| u.has_no_role! :responsible, @data_column unless new_people.include?(u.id.to_s)}
      
    # Check all new people whether they were responsible before. If not, add them.
    new_people.each{|p| User.find(p).has_role! :responsible, @data_column unless @data_column.users.include?(User.find(p))}
    
    # When the comment field was actually changed, we need to save this.
    # TODO: Sophia and I agreed to rename this column, as 'comment' is a too generic name.
    unless @data_column.comment == params[:comment]
      @data_column.comment = params[:comment]
      @data_column.save
    end
    
    # Redirect back so we render the same view again.
    redirect_to :back
  end

  # This method is called whenever someone clicks on the 'Save Data Type' Button
  # in the Data Column approval process.
  #
  # The datatype of this Data Column is saved and the respective Sheetcells are updated.
  def update_datatype
    # Find the called Data Column and update its datatype attribute.
    @data_column = Datacolumn.find(params[:id])
    @data_column.update_attributes(params[:datacolumn])

    # Selecting a datatype means that imported values can now be safely moved to stored values.
    @data_column.add_data_values
    
    # Update the datatype approval flag and save.
    @data_column.datatype_approved = true
    @data_column.save
    
    # Redirect back so we render the same view again.
    redirect_to :back
  end
end
