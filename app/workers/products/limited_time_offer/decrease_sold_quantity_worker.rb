# frozen_string_literal: true

module Products
  module LimitedTimeOffer
    # Decreases the order quantity for shipments with limited time offer products.
    class DecreaseSoldQuantityWorker
      include Sidekiq::Worker
      include WorkerErrorHandling

      sidekiq_options retry: true,
                      retry_count: 3,
                      queue: 'internal',
                      lock: :until_executed

      def perform_with_error_handling(shipment_id)
        @shipment = Shipment.find(shipment_id)

        return unless shipment_got_paid?

        @shipment.order_items.includes(:product).each do |item|
          next unless item.product.limited_time_offer?

          Products::LimitedTimeOffer::DecreaseSoldQuantity.call(item.product, item.quantity)
        end
      end

      private

      def shipment_got_paid?
        @shipment.state_machine.history.exists?(to_state: :paid)
      end
    end
  end
end
