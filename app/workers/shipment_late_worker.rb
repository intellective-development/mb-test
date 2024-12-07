class ShipmentLateWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options retry: false,
                  queue: 'internal',
                  lock: :until_executing

  def perform_with_error_handling(shipment_id)
    shipment = Shipment.find(shipment_id)
    shipment.process_late_shipment
  end
end
