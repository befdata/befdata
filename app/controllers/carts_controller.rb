class CartsController < ApplicationController
  def show
    @cart = current_cart
  end

  def create_cart_context
    @context =Context.find(params[:context_id])
    @cart_context = CartContext.create!(:cart => current_cart, :context => @context)
    flash[:notice] = "Added #{@context.title} to cart."
    redirect_to :back
  end

  def delete_cart_context
    @cart_context =  CartContext.find(params[:cart_context_id])
    @cart_context.destroy
    redirect_to :back
  end

end
