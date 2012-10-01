class DatacolumnsController < ApplicationController

  before_filter :load_datacolumn_and_dataset

  skip_before_filter :deny_access_to_all
  access_control do
    actions :edit, :update_datagroup, :update_datatype, :update_metadata, :update_invalid_values,
            :approval_overview do
      allow :admin
      allow :owner, :of => :dataset
      allow :proposer, :of => :dataset
    end
  end

  layout :choose_layout

  def approval_overview

  end

  def next_approval_step

  end

  def approve_datagroup

  end

  def approve_datatype

  end

  def approve_metadata

  end

  def approve_invalid_values

  end

  # This method provides all neccessary informations
  # for the display of the Data Column approval pages.
  def edit
    begin
      @data_groups_available = Datagroup.all(:order => "title", :conditions => ["id <> ?", @datacolumn.datagroup.id])

      # Is the Data Group of this Data Column approved? If no, then render the Data Group approval partial.
      unless @datacolumn.datagroup_approved?
        render :partial => 'approve_datagroup' and return
      end

      # get the datatype of this column for correct preselection
      @datatype = Datatypehelper.find_by_name(@datacolumn.import_data_type)

      # Is the Data Type of this Data Column approved? If no, then render the Data Type approval partial.
      unless @datacolumn.datatype_approved?
        render :partial => 'approve_datatype' and return
      end

      @available_categories = @datacolumn.datagroup.categories.order(:short)
      @invalid_values_hash = @datacolumn.invalid_values

      # User has to have a look on values that were marked as invalid
      unless @invalid_values_hash.blank?
        render :partial => 'approve_categories' and return
      end
      # Collect all methods for the select tag.
      @methods_short_list = Datagroup.all(:order => "title").collect{|m| [m.title, m.id]}

      # Collect the already linked people.
      @ppl = @datacolumn.users

      # Unfinished datacolumn means, the user must have at least one look on the metadata and members involved.
      unless @datacolumn.finished
        render :partial => 'approve_metadata' and return
      end
      render :layout => false
    rescue
      # The tabbed display prevent the usual error messages from being displayed.
      # We therefore catch all exceptions and display a generic error message along with the exception itself.
      render :text => "Sorry, there is a problem loading the page. Error: #{$!}"
      #raise
    end
  end

  # This method is called whenever someone clicks on the 'Save Data Group' Button
  # in the Data Column approval process.
  def update_datagroup
    # Whenever the datagroup parameter is '-1' this means that
    # the Data Group was not chosen bur submitted via the manual form.
    unless params[:datagroup] == '-1'
      # The datagroup parameter is not '-1'. Go find it in the Database and assign it to this Data Column.
      @datagroup = Datagroup.find(params[:datagroup])
      @datacolumn.approve_datagroup(@datagroup)

      # Create a nice success message and redirect back so we render the same view again.
      flash[:notice] = "Data group successfully saved."
      redirect_to :back
    else
      # The datagroup parameter was '-1', hence we need to create a new Data Group.
      begin
        # Create the new Data Group and save it to the database.
        @datagroup = Datagroup.new(params[:new_datagroup])
        Datacolumn.transaction do
          if @datagroup.save
            # When properly saved, assign the new Data Group to this Data Column,
            @datacolumn.approve_datagroup(@datagroup)
            # Generate a nice success message and redirect back so we render the same view again.
            flash[:notice] = "Data group successfully saved."
            redirect_to :back
          else
            # When saving went wrong, generate a failure message and redirect back anyway.
            flash[:error] = "#{@datagroup.errors.to_a.first.capitalize}"
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
    @datacolumn.approve_datatype(params[:datacolumn], current_user)

    # Create a nice success message and redirect back so we render the same view again.
    flash[:notice] = "Data type successfully saved."
    redirect_to :back
  end


  # The meta data of this Data Column is saved. The people submitted via form are assigned
  # to the Data Column or their assignation is revoked.
  def update_metadata

    unless @datacolumn.update_attributes(params[:datacolumn])
      # Error message when updating failed. Redirect to the last view anyway.
      flash[:error] = "#{@datacolumn.errors.to_a.first.capitalize}"
      redirect_to :back
    end

    # Retrieve the new list of people from the form params.
    new_people = params[:people] ||= []

    # Check all currently responsible users whether they are also new people. If not, remove them.
    @datacolumn.users.each{|u| u.has_no_role! :responsible, @datacolumn unless new_people.include?(u.id.to_s)}

    # Check all new people whether they were responsible before. If not, add them.
    new_people.each{|p| User.find(p).has_role! :responsible, @datacolumn unless @datacolumn.users.include?(User.find(p))}

    @datacolumn.update_attributes({:finished => true})

    # Create a nice success message and redirect back so we render the same view again.
    flash[:notice] = "Metadata and acknowledgements successfully saved."
    redirect_to :back
  end

  # creates categories for all invalid values completed in the form and assigns the category to the sheetcell
  def update_invalid_values
    if(!@datacolumn.nil?)
      @datacolumn.invalid_values.each do |value, i|
        short = params["short_value_#{i}"].empty? ? nil : params["short_value_#{i}"]
        long = params["long_value_#{i}"].empty? ? nil : params["long_value_#{i}"]
        description = params["description_#{i}"].empty? ? nil : params["description_#{i}"]

        if(!short.nil?)
          @datacolumn.update_invalid_value(value, short, long, description, current_user, @dataset)
        end
      end
      @datacolumn.update_attribute(:updated_at, Time.now)
      flash[:notice] = "The invalid values have been successfully approved"
      redirect_to :back
    end
  end

  private

  def choose_layout
    if request.xhr?
      nil
    elsif [].include? action_name
      'application'
    else
      'approval'
    end
  end

  def load_datacolumn_and_dataset
    @datacolumn = Datacolumn.find(params[:id])
    @dataset = @datacolumn.dataset
  end

end
