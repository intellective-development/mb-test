# frozen_string_literal: true

module Products
  module LimitedTimeOffer
    # Increases the order quantity limited time offer products.
    class IncreaseSoldQuantity < BaseService
      attr_reader :product, :quantity

      def initialize(product, quantity)
        super

        @product = product
        @quantity = quantity
      end

      def call
        return unless product.limited_time_offer
        return if global_limit.zero?

        increase_order_quantity
      end

      private

      def increase_order_quantity
        product.limited_time_offer_data[Product::LTO_SOLD_QUANTITY_KEY] ||= 0
        product.limited_time_offer_data[Product::LTO_SOLD_QUANTITY_KEY] += quantity

        deactivate_limited_time_offer if product.limited_time_offer_data[Product::LTO_SOLD_QUANTITY_KEY] >= global_limit

        product.save
      end

      def deactivate_limited_time_offer
        Products::LimitedTimeOffer::DeactivateProductWorker.perform_async(product.id)
      end

      def global_limit
        product.limited_time_offer_data[Product::LTO_GLOBAL_LIMIT_KEY].to_i
      end
    end
  end
end
