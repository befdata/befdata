class TagsController < ApplicationController
  skip_before_filter :deny_access_to_all
  access_control do
    actions :index, :show do
      allow all
    end
  end

  def index
    @tags = Tag.all :order => :name
  end

  def show
    redirect_to(:action => "index") and return if params[:id].blank?
    @tag = Tag.first(:conditions => ["id = ?", params[:id]], :include => :taggings)
    return redirect_to(:action => "index", :status => :not_found) unless @tag

    taggings_datasets = @tag.taggings.select{|ti| ti.taggable_type == "Dataset"}
    tag_datasets = taggings_datasets.collect{|ti| ti.taggable}
    taggings_datacolumns = @tag.taggings.select{|ti| ti.taggable_type == "Datacolumn"}
    tag_dc_datasets = taggings_datacolumns.collect{|ti| ti.taggable.dataset}.uniq
    unique_datasets = (tag_datasets + tag_dc_datasets).uniq
    non_destroy_datasets = unique_datasets.find_all{|d| !d.destroy_me}
    @datasets = non_destroy_datasets.sort_by {|x| x.title}
  end

end
