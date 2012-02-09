class CategoriesController < ApplicationController

  skip_before_filter :deny_access_to_all
  access_control do
    actions :index, :show do
      allow logged_in
    end
  end

  def index
    @categories = Category.order(:short)
  end

  def show
    @category = Category.find params[:id]
  end

end