# frozen_string_literal: true

module Products
  module LimitedTimeOffer
    # Increases the order quantity for shipments with limited time offer products.
    class DeactivateProductWorker
      include Sidekiq::Worker
      include WorkerErrorHandling

      sidekiq_options retry: true,
                      retry_count: 3,
                      queue: 'high_priority',
                      lock: :until_executed

      def perform_with_error_handling(product_id)
        product = Product.find(product_id)

        product.limited_time_offer = false
        product.deactivate!
      end
    end
  end
end
