class CartsController < ApplicationController

  def show
    @cart = current_cart
  end

  def create_cart_context
    @dataset = Dataset.find(params[:dataset_id])
    @cart_dataset = CartDataset.create!(:cart => current_cart, :context => @dataset)
    flash[:notice] = "Added #{@dataset.title} to cart."
    redirect_to :back
  end

  def delete_cart_context
    @cart_dataset =  CartDataset.find(params[:cart_dataset_id])
    @cart_dataset.destroy
    redirect_to :back
  end
end
