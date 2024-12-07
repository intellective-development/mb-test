class CartsController < ApplicationController
  def claim
    # cookies.signed[:cart_id] = params[:id]
    # cookies.signed[:cart_claim] = true
    redirect_to '/store/cart'
  end
end
