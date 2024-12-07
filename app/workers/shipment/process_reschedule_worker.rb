class Shipment::ProcessRescheduleWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options queue: 'internal',
                  retry: 5

  def perform_with_error_handling(shipment_id)
    shipment = Shipment.find shipment_id
    return unless shipment.scheduled?

    last_transition = ShipmentTransition.where(most_recent: true, shipment_id: shipment_id).take
    shipment.comments.create(note: 'This order has an updated scheduled delivery time.  We suggest you reprint the order slip which has been updated with the correct information', created_by: last_transition && last_transition.metadata['user_id'])

    Shipment::RescheduleDeliveryServiceWorker.perform_async(shipment_id, shipment.supplier.delivery_service_id)
  end
end
