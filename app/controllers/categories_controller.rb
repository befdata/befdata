class CategoriesController < ApplicationController

  skip_before_filter :deny_access_to_all

  access_control do
    actions :show do
      allow logged_in
    end
  end

  def show
    @category = Category.find params[:id]
    @datasets = @category.datasets
  end

end