class CancelDeliveryServiceWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options queue: 'internal',
                  retry: 5

  def perform_with_error_handling(cancellable_id, delivery_service_id, is_order = true)
    delivery_service = DeliveryService.find(delivery_service_id)

    if is_order
      case delivery_service.name
      when 'DoorDash'
        DoorDashService.new.cancel_order(cancellable_id)
      when 'UberDaas'
        shipments = Shipment.joins(supplier: :delivery_service).where(order_id: cancellable_id, delivery_service: { name: 'UberDaas' })
        shipments.each { |shipment| UberDaasService.new(shipment.id).cancel_shipment }
      when 'DeliverySolutions'
        DeliverySolutionsService.new.cancel_order(delivery_service)
      when 'Zifty'
        ZiftyService.new.cancel_order(cancellable_id)
      end
    else
      case delivery_service.name
      when 'DoorDash'
        DoorDashService.new.cancel_shipment(cancellable_id)
      when 'UberDaas'
        UberDaasService.new(cancellable_id).cancel_shipment
      when 'DeliverySolutions'
        DeliverySolutionsService.new.cancel_shipment(delivery_service)
      when 'Zifty'
        ZiftyService.new.cancel_shipment(cancellable_id)
      end
    end
  end
end
