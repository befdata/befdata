require 'csv'

class DatagroupsController < ApplicationController

  skip_before_filter :deny_access_to_all
  access_control do
    actions :index, :show do
      allow logged_in
    end
  end

  def index
    @datagroups = Datagroup.order(:title)
  end

  def show
    @datagroup = Datagroup.find params[:id]
    respond_to do |format|
      format.html
      format.csv do
        send_data render_categories_csv, :type => "text/plain", :filename=>"#{@datagroup.title}_categories.csv", :disposition => 'attachment'
      end
    end
  end

  def render_categories_csv
    csv_string = CSV.generate do |csv|
      csv << ["ID","SHORT","LONG","DESCRIPTION"]
      @datagroup.categories.sort_by(&:short).each do |cat|
        csv << [cat.id, cat.short, cat.long, cat.description]
      end
    end
  end

end