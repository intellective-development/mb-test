# frozen_string_literal: true

module Orders
  # Orders::ChangeAddressService
  #
  # Service that changes the order address and update items
  class ChangeAddressService < BaseService
    attr_reader :order, :user, :new_address, :order_items

    def initialize(order, user, new_address, order_items)
      @order = order
      @user = user
      @new_address = new_address
      @order_items = order_items
      super
    end

    def call
      update_cart_items if cart.present?

      update_order

      self
    end

    def update_cart_items
      cart.cart_items.each do |cart_item|
        order_item = order_item_by_variant(cart_item.variant_id)
        order_item_params = order_items.find { |item| item[:ordem_item_id] == order_item.id }

        cart_item_params = cart_item_params(cart_item, order_item_params)

        ::Carts::ProcessCartItem.call(cart, cart_item, cart_item_params, order.storefront)
      end
    end

    def update_order
      order_service = OrderCreationServices.new(
        order, user, order.cart, order_creation_params, skip_in_stock_check: @order.disable_in_stock_check?
      )

      order_service.build_order
      order.save
    end

    def cart_item_params(cart_item, order_item_params)
      {
        identifier: cart_item.identifier,
        variant_id: order_item_params.dig(:new_product, :variant_id),
        quantity: order_item_params[:new_product].present? ? cart_item.quantity : 0,
        product_bundle: cart_item.product_bundle,
        customer_placement: cart_item.customer_placement,
        item_options: cart_item.item_options
      }
    end

    def order_creation_params
      {
        cart_id: order.cart&.id,
        order_items: build_order_items,
        shipping_address_id: new_address.id
      }
    end

    def build_order_items
      order_items.filter_map do |order_item|
        next if order_item[:new_product].blank?

        current_order_item = order.order_items.find { |item| item.id == order_item[:ordem_item_id] }
        {
          variant_id: order_item[:new_product][:variant_id],
          quantity: current_order_item.quantity
        }
      end
    end

    def order_item_by_variant(variant_id)
      order.order_items.find { |item| item.variant_id == variant_id }
    end

    def cart
      @cart ||= order.cart
    end
  end
end
