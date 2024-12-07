class Shipment::WithoutTrackingNumberWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options retry: 5,
                  queue: 'default'

  def perform_with_error_handling(shipment_id)
    shipment = Shipment.find shipment_id

    return if shipment.shipped_with_tracking_number?

    shipment.broadcast_event(:shipment_no_tracking_number)
  end
end
