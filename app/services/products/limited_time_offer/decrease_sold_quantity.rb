# frozen_string_literal: true

module Products
  module LimitedTimeOffer
    # Decrease the limited time offer order quantity on products.
    class DecreaseSoldQuantity < BaseService
      attr_reader :product, :quantity

      def initialize(product, quantity)
        super

        @product = product
        @quantity = quantity
      end

      def call
        return unless product.limited_time_offer
        return if global_limit.zero?

        decrease_order_quantity
      end

      private

      def decrease_order_quantity
        current_sold_quantity = product.limited_time_offer_data[Product::LTO_SOLD_QUANTITY_KEY] || 0
        new_sold_quantity = current_sold_quantity - quantity
        product.limited_time_offer_data[Product::LTO_SOLD_QUANTITY_KEY] = [new_sold_quantity, 0].max

        product.save
      end

      def global_limit
        product.limited_time_offer_data[Product::LTO_GLOBAL_LIMIT_KEY].to_i
      end
    end
  end
end
