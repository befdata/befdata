class TagsController < ApplicationController
  skip_before_filter :deny_access_to_all
  access_control do
    actions :index, :show do
      allow all
    end
  end

  def index
    @tags = ActsAsTaggableOn::Tag.where("lower(name) like ?", "%#{params[:q] && params[:q].downcase}%").order(:name)
    respond_to do |format|
      format.html
    format.json { render :json=> @tags.map(&:attributes)}
    end
  end

  def show
    redirect_to(:action => "index") and return if params[:id].blank?
    @tag = ActsAsTaggableOn::Tag.find(params[:id])
    return redirect_to(:action => "index", :status => :not_found) unless @tag

    tag_datasets = Dataset.tagged_with(@tag.name)
    tag_dc_datasets = Datacolumn.tagged_with(@tag.name).map(&:dataset)
    @datasets = (tag_datasets + tag_dc_datasets).flatten.uniq.sort_by(&:title)
  end

end
