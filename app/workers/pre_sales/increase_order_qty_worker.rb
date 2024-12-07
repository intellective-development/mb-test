# frozen_string_literal: true

module PreSales
  # Increases the order quantity for pre-sale shipments.
  class IncreaseOrderQtyWorker
    include Sidekiq::Worker
    include WorkerErrorHandling

    sidekiq_options retry: true,
                    retry_count: 3,
                    queue: 'high_priority',
                    lock: :until_executed

    def perform_with_error_handling(shipment_id)
      MetricsClient::Metric.emit('minibar_web.pre_sale.increasing', 1)

      shipment = Shipment.find(shipment_id)
      PreSales::IncreaseOrderQuantity.new(shipment).call
    end
  end
end
