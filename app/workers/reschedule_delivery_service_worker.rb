class RescheduleDeliveryServiceWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options queue: 'internal',
                  retry: 5

  def perform_with_error_handling(order_id, delivery_service_id)
    delivery_service = DeliveryService.find(delivery_service_id)
    case delivery_service.name
    when 'DoorDash'
      DoorDashService.new.reschedule_order(order_id)
    when 'DeliverySolutions'
      DeliverySolutionsService.new.reschedule_order(order_id)
    when 'Zifty'
      ZiftyService.new.reschedule_order(order_id)
    end
  end
end
