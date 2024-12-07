# frozen_string_literal: true

module Orders
  # Orders::ChangesOnAddressUpdateService
  #
  # Service return the ordem items changes with a new address
  class ChangesOnAddressUpdateService
    attr_reader :order, :new_address, :storefront, :order_item_changes

    def initialize(order, new_address, storefront)
      @order = order
      @new_address = new_address
      @storefront = storefront
      @order_item_changes = []
    end

    def call
      order.shipments.each do |shipment|
        shipping_type = shipment.shipping_type.to_sym

        shipment.order_items.each do |item|
          add_order_item_changes(item, shipping_type)
        end
      end

      order_item_changes
    end

    private

    def add_order_item_changes(item, shipping_type)
      products = rsa_products.select do |product|
        product.product_id == item.variant.product_id &&
          product.shipping_method == shipping_type &&
          product.in_stock >= item.quantity
      end

      error_message = products.blank? ? 'Not Avaliable on this state' : nil

      new_product = products.min_by(&:price)

      if products.present? && item.engraving?
        new_product = products.select { |product| product.type == :engraving }.min_by(&:price)

        error_message = 'Engraving not avaliable for this product' if new_product.blank?
      end

      @order_item_changes << {
        ordem_item_id: item.id,
        new_product: new_product,
        error_message: error_message
      }
    end

    def product_ids
      order.order_items.filter_map do |item|
        next if item.product_bundle_id.present?

        "PRODUCT-#{item.variant.product_id}"
      end
    end

    def bundle_ids
      order.order_items.filter_map do |item|
        next if item.product_bundle_id.blank?

        item.product_bundle.external_id
      end.uniq
    end

    def rsa_products
      @rsa_products ||= ::RSA::MultiSelectService.call(storefront.id, nil, product_ids, bundle_ids, nil, new_address)
    end
  end
end
