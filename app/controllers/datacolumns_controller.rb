class DatacolumnsController < ApplicationController

  before_filter :load_datacolumn_and_dataset

  skip_before_filter :deny_access_to_all
  access_control do
    actions :approval_overview, :next_approval_step,
            :approve_datagroup, :approve_datatype, :approve_metadata, :approve_invalid_values,
            :update_datagroup, :update_datatype, :update_metadata, :update_invalid_values do
      allow :admin
      allow :owner, :of => :dataset
      allow :proposer, :of => :dataset
    end
  end

  layout :choose_layout

  def approval_overview
  end

  def next_approval_step
    unless @datacolumn.datagroup_approved?
      redirect_to :action => "approve_datagroup" and return
    end
    unless @datacolumn.datatype_approved?
      redirect_to :action => "approve_datatype" and return
    end
    unless @datacolumn.invalid_values.blank?
      redirect_to :action => "approve_invalid_values" and return
    end
    unless @datacolumn.finished
      redirect_to :action => "approve_metadata" and return
    end
    redirect_to :action => "approval_overview"
  end

  def approve_datagroup
    @data_groups_available = Datagroup.all(:order => "title", :conditions => ["id <> ?", @datacolumn.datagroup.id])
  end

  def approve_datatype
    @datatype = Datatypehelper.find_by_name(@datacolumn.import_data_type)
  end

  def approve_invalid_values
    @available_categories = @datacolumn.datagroup.categories.order(:short)
    @invalid_values_hash = @datacolumn.invalid_values
  end

  def approve_metadata
    @methods_short_list = Datagroup.all(:order => "title").collect{|m| [m.title, m.id]}
    @ppl = @datacolumn.users
    # TODO also give a list of not matched names (alread in view)
    # @ppl_not_found = ???
  end

  # This method is called whenever someone clicks on the 'Save Data Group' Button
  # in the Data Column approval process.
  def update_datagroup
    case params[:datagroup]
      when nil
        flash[:error] = "You need to choose a datagroup to assign."
        redirect_to :back and return
      when '-1' #indicates a new datagroup
        begin
          @datagroup = Datagroup.new(params[:new_datagroup])
          Datacolumn.transaction do
            if @datagroup.save
              @datacolumn.approve_datagroup(@datagroup)
              flash[:notice] = "Data group successfully saved."
              redirect_to :action => "next_approval_step"
            else
              flash[:error] = "#{@datagroup.errors.to_a.first.capitalize}"
              redirect_to :back
            end
          end
        # This Exception is thrown by 'save' when the record-to-save could not be validated.
        rescue ActiveRecord::RecordInvalid => invalid
          flash[:error] = "#{invalid.errors.to_a.first.capitalize}"
          redirect_to :back
        end
      else
        @datagroup = Datagroup.find(params[:datagroup])
        @datacolumn.approve_datagroup(@datagroup)
        flash[:notice] = "Data group successfully saved."
        redirect_to :action => "next_approval_step"
    end
  end

  # This method is called whenever someone clicks on the 'Save Data Type' Button
  # in the Data Column approval process.
  #
  # The datatype of this Data Column is saved and the respective Sheetcells are updated.
  def update_datatype
    begin
      @datacolumn.approve_datatype(params[:datacolumn][:import_data_type], current_user)
      flash[:notice] = params[:datacolumn][:import_data_type]
      redirect_to :action => "next_approval_step"
    rescue
      flash[:error] = "An error occured while updating the datatype: #{$!}"
      redirect_to :back
    end
  end


  # The meta data of this Data Column is saved. The people submitted via form are assigned
  # to the Data Column or their assignation is revoked.
  def update_metadata

    unless @datacolumn.update_attributes(params[:datacolumn])
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

    flash[:notice] = "Metadata and acknowledgements successfully saved."
    redirect_to :action => "next_approval_step"
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
      redirect_to :action => "next_approval_step"
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
