class DatacolumnsController < ApplicationController

  # ACL9 access block for the methods of this controller.
  skip_before_filter :deny_access_to_all
  access_control do
    actions :edit, :update_datagroup, :update_datatype, :update_metadata, :update_invalid_values do
      allow :admin
      allow :owner, :of => :dataset
      allow :proposer, :of => :dataset
    end
  end

  # This method provides all neccessary informations
  # for the display of the Data Column approval pages.
  def edit
    begin
      # Get the central Data Column object from the database.
      @data_column ||= Datacolumn.find(params[:id])

      # We're working with the Data Workbook, too. Thus, we have to load it.
      @book = Dataworkbook.new(@data_column.dataset.upload_spreadsheet)

      # We extract the column header to determine the available Data Groups from the Data Workbook.
      columnheader = @data_column.columnheader
      data_group_title = @data_column.datagroup.title
      @data_groups_available = Datagroup.all.delete_if{|d| d == @data_column.datagroup}

      # Is the Data Group of this Data Column approved? If no, then render the Data Group approval partial.
      unless @data_column.datagroup_approved?
        render :partial => 'approve_datagroup' and return
      end

      # get the datatype of this column for correct preselection
      @datatype = Datatypehelper.find_by_name(@data_column.import_data_type)

      # Is the Data Type of this Data Column approved? If no, then render the Data Type approval partial.
      unless @data_column.datatype_approved?
        render :partial => 'approve_datatype' and return
      end

      @dataset = @data_column.dataset
      @available_categories = @data_column.datagroup.categories.order(:short)
      @invalid_values_hash = @data_column.invalid_values

      # User has to have a look on values that were marked as invalid
      unless @invalid_values_hash.blank?
        render :partial => 'approve_categories' and return
      end
      # Collect all methods for the select tag.
      @methods_short_list = Datagroup.find(:all, :order => "title").collect{|m| [m.title, m.id]}

      # Collect the already linked people.
      @ppl = @data_column.users

      # Unfinished datacolumn means, the user must have at least one look on the metadata and members involved.
      unless @data_column.finished
        render :partial => 'approve_metadata' and return
      end
      render :layout => false
    rescue
      # The tabbed display prevent the usual error messages from being displayed.
      # We therefore catch all exceptions and display a generic error message along with the exception itself.
      render :text => "Sorry, something went wrong! #{$!}"
      #raise
    end
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
      flash[:notice] = "Data Group successfully saved."
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
            flash[:notice] = "Data Group successfully saved."
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

  # This method is called whenever someone clicks on the 'Save Data Type' Button
  # in the Data Column approval process.
  #
  # The datatype of this Data Column is saved and the respective Sheetcells are updated.
  def update_datatype
    # Find the called Data Column and update its datatype attribute.
    @data_column = Datacolumn.find(params[:id])
    @data_column.update_attributes(params[:datacolumn])

    # Selecting a datatype means that imported values can now be safely moved to stored values.
    @data_column.add_data_values(current_user)

    # Update the datatype approval flag and save.
    @data_column.datatype_approved = true
    @data_column.save

    # Create a nice success message and redirect back so we render the same view again.
    flash[:notice] = "Data Type successfully saved."
    redirect_to :back
  end


  # The meta data of this Data Column is saved. The people submitted via form are assigned
  # to the Data Column or their assignation is revoked.
  def update_metadata
    # Find the called Data Column and update its metadata.
    @data_column = Datacolumn.find(params[:id])

    unless @data_column.update_attributes(params[:datacolumn])
      # Error message when updating failed. Redirect to the last view anyway.
      flash[:error] = "#{@data_column.errors.to_a.first.capitalize}"      
      redirect_to :back
    end

    # Retrieve the new list of people from the form params.
    new_people = params[:people] ||= []

    # Check all currently responsible users whether they are also new people. If not, remove them.
    @data_column.users.each{|u| u.has_no_role! :responsible, @data_column unless new_people.include?(u.id.to_s)}

    # Check all new people whether they were responsible before. If not, add them.
    new_people.each{|p| User.find(p).has_role! :responsible, @data_column unless @data_column.users.include?(User.find(p))}

    @data_column.update_attributes({:finished => true})

    # Create a nice success message and redirect back so we render the same view again.
    flash[:notice] = "Metadata and Members involved successfully saved."
    redirect_to :back
  end

  # creates categories for all invalid values completed in the form and assigns the category to the sheetcell
  def update_invalid_values
    @data_column = Datacolumn.find(params[:id])
    if(!@data_column.nil?)
      dataset = @data_column.dataset
      @data_column.invalid_values.each do |value, i|
        short = params["short_value_#{i}"].empty? ? nil : params["short_value_#{i}"]
        long = params["long_value_#{i}"].empty? ? nil : params["long_value_#{i}"]
        description = params["description_#{i}"].empty? ? nil : params["description_#{i}"]

        if(!short.nil?)
          @data_column.update_invalid_value(value, short, long, description, current_user, dataset)
        end
      end
      flash[:notice] = "The invalid values have been successfully approved"
      redirect_to :back
    end
  end

end
