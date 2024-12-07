# frozen_string_literal: true

module Carts
  # Carts::ProcessCartItem
  #
  # Service that Create, Update and Delete cart items
  class ProcessCartItem < BaseService
    attr_reader :cart, :cart_item, :item_params, :storefront, :error_message

    def initialize(cart, cart_item, item_params, storefront)
      @cart = cart
      @cart_item = cart_item
      @item_params = item_params
      @storefront = storefront
      super
    end

    def call
      @cart_item = process_cart_item

      self
    end

    private

    def process_cart_item
      return destroy_cart_item(item_params).first if cart_item && item_params[:quantity].zero?

      variant_reached_limit_by_user(item_params[:variant_id], item_params[:identifier], item_params[:quantity])

      return update_cart_item(cart_item, item_params) if cart_item
      return create_cart_item(item_params) if variant_available?(item_params[:variant_id])

      raise StandardError, "Product #{item_params[:variant_id]} is not valid."
    rescue StandardError => e
      @error_message = e.message

      nil
    end

    def create_cart_item(cart_item_params)
      variant_id = cart_item_params[:variant_id]

      raise StandardError, "Product #{variant_id} is invalid or sold out." unless variant_available?(variant_id)

      cart.add_item(cart_item_params.merge(user: @user),
                    ItemType::SHOPPING_CART_ID,
                    use_in_stock_check?)
    end

    def update_cart_item(cart_item, cart_item_params)
      cart_item_params.merge!(item_options: cart_item.variant.read_options(cart_item_params[:item_options])) if cart_item.variant.present?
      cart_item.update(cart_item_params.merge(active: true))
      cart_item
    end

    def destroy_cart_item(cart_item_params)
      cart.remove_item(cart_item_params[:identifier])
    end

    def variant_reached_limit_by_user(variant_id, identifier, quantity)
      return if Feature[:skip_max_quantity_per_order_feature].enabled?

      product = Product.joins(:variants)
                       .find_by(variants: { id: variant_id })

      raise StandardError, "You have reached the purchase limit for the product #{product.name}." if LimitedProductOrder.limit_reached_in_cart?(cart, product, identifier, quantity)
    end

    def variant_available?(variant_id)
      return Variant.available.exists?(variant_id) if use_in_stock_check?

      Variant.exists?(variant_id)
    end

    def use_in_stock_check?
      storefront.default_storefront? || !!storefront.enable_in_stock_check
    end
  end
end
