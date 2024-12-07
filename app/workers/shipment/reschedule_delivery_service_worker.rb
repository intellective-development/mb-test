class Shipment::RescheduleDeliveryServiceWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options queue: 'internal',
                  retry: 5

  def perform_with_error_handling(shipment_id, delivery_service_id)
    return unless delivery_service_id.present?

    delivery_service = DeliveryService.find(delivery_service_id)
    case delivery_service.name
    when 'DoorDash'
      DoorDashService.new.reschedule_shipment(shipment_id)
    when 'DeliverySolutions'
      DeliverySolutionsService.new.reschedule_shipment(shipment_id)
    when 'Zifty'
      ZiftyService.new.reschedule_shipment(shipment_id)
    end
  end
end
