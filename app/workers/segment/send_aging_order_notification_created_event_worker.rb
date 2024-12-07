class Segment::SendAgingOrderNotificationCreatedEventWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options \
    queue: 'sync_profile',
    retry: 5,
    lock: :until_executing

  def perform_with_error_handling(shipment_id)
    shipment = Shipment.find(shipment_id)

    return if shipment.on_demand?
    return unless shipment.customer_placement_standard?
    return if shipment.in_state?(ShipmentStateMachine::AGING_ORDER_NOTIFICATION_IGNORED_STATES)
    return unless shipment.age_in_days.in?(Shipment::AGE_IN_DAYS_TO_FIRE_AGING_EVENTS)
    return if shipment.packages.any?

    Segments::SegmentService.from(shipment.order.storefront).aging_order_notification_created(shipment)
  end
end
