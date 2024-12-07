class Supplier::IncreaseDailyShippingCountWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options retry: true,
                  queue: 'internal',
                  lock: :until_and_while_executing

  def perform_with_error_handling(shipment_id)
    shipment = Shipment.find(shipment_id)

    shipment.supplier.increment!(:daily_shipping_count, 1)
  end
end
