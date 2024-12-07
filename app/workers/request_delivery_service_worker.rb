class RequestDeliveryServiceWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options queue: 'internal',
                  retry: 5

  def perform_with_error_handling(shipment_id, postponed_arrival_time = nil)
    shipment = Shipment.find(shipment_id)
    delivery_service = DeliveryService.find(shipment.delivery_service_id) if shipment.delivery_service_id.present?
    delivery_service ||= shipment.delivery_service
    return if delivery_service.nil?
    return if shipment.pickup?
    return if shipment.shipped?

    case delivery_service.name
    when 'CartWheel'
      CartWheelService.new(shipment).create_delivery
    when 'DoorDash'
      DoorDashService.new.create_delivery(shipment_id, postponed_arrival_time) unless shipment.liquid_shipment?
    when 'UberDaas'
      UberDaasService.new(shipment_id).create_delivery
    when 'DeliverySolutions'
      DeliverySolutionsService.new.create_delivery(shipment_id)
    when 'Zifty'
      ZiftyService.new.create_delivery(shipment_id)
    end
  end
end
