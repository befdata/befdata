class TagsController < ApplicationController
  skip_before_filter :deny_access_to_all
  before_filter :load_keywords, only: [:delete, :pre_rename, :pre_merge, :merge]
  access_control do
    allow all, :to => [:index, :show]
    actions :manage, :pre_rename, :rename, :delete, :pre_merge, :merge do
      allow :admin, :data_admin
    end
  end

  def index
    @tags = DatasetTag.tag_counts.where("name iLike ?", "%#{params[:q]}%")

    respond_to do |format|
      format.html
      format.json { render :json => @tags}
      format.xml
    end
  end

  def show
    @tag = ActsAsTaggableOn::Tag.find(params[:id])
    @datasets = Dataset.joins(:dataset_tags)
                       .select("datasets.id, title")
                       .where(['dataset_tags.tag_id = ?', @tag.id])
                       .order("lower(datasets.title)")

    respond_to do |format|
      format.html
      format.csv do
        send_data render_datasets_csv, :type => "text/csv", :filename=>"datasets_tagged_with_#{@tag.name}.csv", :disposition => 'attachment'
      end
    end
  end

  def manage
    @all_tags = DatasetTag.tag_counts
  end

  def delete
    @keywords.each {|t| t.destroy}
    flash[:notice] = "Deleted #{@keywords.count} keywords."
    redirect_to :back
  end

  def pre_rename
  end

  def rename
    all_keywords = ActsAsTaggableOn::Tag.update(params[:keywords].keys, params[:keywords].values)
    @keywords = all_keywords.reject {|t| t.errors.empty? }
    if @keywords.empty?
      flash[:notice] = "Successfully updated #{all_keywords.length} keywords"
      redirect_to manage_keywords_path
    else
      flash.now[:error] = "#{(all_keywords-@keywords).length} keywords were updated successfully; However, #{@keywords.length} keywords were not successfully updated"
      render :action => :pre_rename
    end
  end

  def pre_merge
  end

  def merge
    if params[:new_keyword].present?
      keyword = ActsAsTaggableOn::Tag.find_or_create_all_with_like_by_name(params[:new_keyword]).first
    elsif params[:merge_to].present?
      keyword = ActsAsTaggableOn::Tag.find(params[:merge_to])
    else
      flash.now[:error] = "No keyword specified"
      render :action => :pre_merge and return
    end

    deprecated_tag = @keywords - [keyword]

    taggables = ActsAsTaggableOn::Tagging.where(tag_id: deprecated_tag.map(&:id), taggable_type: %w{Dataset Datacolumn}, context: 'tags')
                  .includes(:taggable).collect {|t| t.taggable}.uniq
    taggables.each do |tg|
      tg.tag_list.remove(deprecated_tag.map(&:name)).add(keyword.name)
      tg.save(:validate => false)
    end

    redirect_to manage_keywords_path, :notice => "Selected keywords were successfully merged."
  end

private
  def load_keywords
    @keywords = ActsAsTaggableOn::Tag.find(params[:keywords])
  end

  def render_datasets_csv
    user_api = current_user.try(:single_access_token)
    CSV.generate do |csv|
      csv << %w(id title emlURL xlsURL csvURL csvSeparatedMixedValueColumnsUrl)
      @datasets.each do |d|
        csv << [d.id, d.title, dataset_url(d, :eml),
                download_dataset_url(d, user_credentials: user_api),
                download_dataset_url(d, :csv, user_credentials: user_api),
                download_dataset_url(d, :csv, separate_category_columns: true, user_credentials: user_api)
               ]
      end
    end
  end
end
