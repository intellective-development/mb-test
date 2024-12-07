class Admin::CartsController < Admin::BaseController
  include GuestAuthenticable

  before_action :set_cart, except: %i[index new create]
  before_action :set_address, only: [:rsa_data]

  def index
    @carts = Cart.where(user_id: params[:user_id].presence || current_user.id)
  end

  def new
    @cart = Cart.new
    @cart.build_cart_trait
  end

  def create
    params[:cart][:user_id] = set_user

    @cart = Cart.new(cart_params)
    if @cart.save
      redirect_to edit_admin_cart_path(@cart)
    else
      flash[:error] = 'The cart could not be saved'
      render action: :new
    end
  end

  def update
    params[:cart][:user_id] = set_user

    if @cart.update(cart_params)
      redirect_to edit_admin_cart_path(@cart)
    else
      flash[:error] = 'The cart could not be updated'
      render action: :edit
    end
  end

  def destroy
    flash[:error] = 'The cart could not be deleted' unless @cart.destroy
    redirect_to(action: :index)
  end

  def rsa_data
    if (params[:product_grouping_id].present? || params[:bundle_id].present?) && params[:address_id].present?
      supplier_ids = @cart.cart_items.joins(:variant).distinct.pluck('"variants"."supplier_id"')
      products = RSA::SelectService.call(params[:storefront_id], params[:product_grouping_id], params[:bundle_id], @address, supplier_ids)
      respond_to do |format|
        format.html { render 'admin/rsa/products/_list', locals: { products: products }, layout: false }
      end
    else
      error_msg = 'Address, Product Grouping ID or Bundle ID is missing'
      respond_to do |format|
        format.html { render 'admin/rsa/products/_list', locals: { error_msg: error_msg }, layout: false }
      end
    end
  end

  def add_products
    CartItem.transaction do
      params[:products].map do |product|
        CartItem.create!(
          identifier: CartItem.generate_identifier(nil, 0, product[:variant_id]),
          item_type_id: ItemType::SHOPPING_CART_ID,
          cart_id: @cart.id,
          quantity: 1,
          product_bundle: ProductBundle.find_by(external_id: product[:bundle_id]),
          variant_id: product[:variant_id],
          customer_placement: product[:customer_placement]
        )
      end
    end
    redirect_to edit_admin_cart_path(@cart)
  end

  private

  def set_user
    params[:cart][:user_id].presence || create_guest_user!(params[:cart][:storefront_id]).id
  end

  def set_address
    @address = Address.find(params[:address_id])
  end

  def cart_params
    params
      .require(:cart)
      .permit(
        :storefront_id, :storefront_cart_id, :user_id,
        cart_trait_attributes: %i[id coupon_code gtm_visitor_id gift_order age_verified]
      )
  end

  def set_cart
    @cart = Cart.find(params[:id] || params[:cart_id])
  end
end
