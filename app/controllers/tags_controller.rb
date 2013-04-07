class TagsController < ApplicationController
  skip_before_filter :deny_access_to_all
  access_control do
    actions :index, :show do
      allow all
    end
  end

  def index
    @tags = Dataset.tag_counts.where("name iLike ?", "%#{params[:q]}%").order("tags.name")
    respond_to do |format|
      format.html
      format.json { render :json=> @tags.map(&:attributes)}
    end
  end

  def show
    @tag = ActsAsTaggableOn::Tag.find(params[:id])
    @datasets = Dataset.tag_usage.select("datasets.*").where("tags.id = ?", @tag.id).order("datasets.title")

    respond_to do |format|
      format.html
      format.csv do
        csvdata = CSV.generate do |csv|
          csv << %w(id title emlURL xlsURL csvURL csvSeparatedMixedValueColumnsUrl)
          user_api = current_user.try(:single_access_token)
          @datasets.each do |d|
            csv << [d.id, d.title, dataset_url(d, :eml),
                    download_dataset_url(d, user_credentials: user_api), 
                    download_dataset_url(d, :csv, user_credentials: user_api),
                    download_dataset_url(d, :csv, separate_category_columns: true, user_credentials: user_api)
                   ]
          end
        end
        send_data csvdata, :type => "text/csv", :filename=>"datasets_tagged_with_#{@tag.name}.csv", :disposition => 'attachment'
      end
    end
  end

end
