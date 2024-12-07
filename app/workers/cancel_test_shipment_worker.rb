class CancelTestShipmentWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  def perform_with_error_handling(shipment_id)
    shipment = Shipment.find(shipment_id)
    shipment.cancel!
    shipment.test!
  end
end
