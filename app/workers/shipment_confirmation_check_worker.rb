class ShipmentConfirmationCheckWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options retry: 10,
                  queue: 'internal',
                  lock: :until_executing

  def perform_with_error_handling(shipment_id)
    shipment = Shipment.find(shipment_id)
    shipment.check_order_confirmation
  end
end
