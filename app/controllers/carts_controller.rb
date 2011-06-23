class CartsController < ApplicationController

  skip_before_filter :deny_access_to_all
  access_control do
    actions :show, :create_cart_context do
      allow logged_in
    end
    action :delete_cart_context do
      allow logged_in #TODO this should be only allowed for the owner of a cart or similar see #4670
    end
  end

  def show
    @cart = current_cart
  end

  def create_cart_context
    @dataset = Dataset.find(params[:dataset_id])
    @cart_dataset = CartDataset.create!(:cart => current_cart, :dataset => @dataset)
    flash[:notice] = "Added #{@dataset.title} to cart."
    redirect_to :back
  end

  def delete_cart_context
    @cart_dataset =  CartDataset.find(params[:cart_dataset_id])
    @cart_dataset.destroy
    redirect_to :back
  end
end
