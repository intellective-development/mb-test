class Segment::SendAgingBackorderNotificationCreatedEventWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options \
    queue: 'sync_profile',
    retry: 5,
    lock: :until_executing

  def perform_with_error_handling
    today = Date.current
    longest = (today - Shipment::AGE_IN_DAYS_TO_FIRE_AGING_EVENTS.max.days).beginning_of_day
    closest = (today - Shipment::AGE_IN_DAYS_TO_FIRE_AGING_EVENTS.min.days).end_of_day

    shipments = Shipment.where(customer_placement: 'back_order')
                        .in_state('back_order')
                        .where('shipments.created_at between ? and ?', longest, closest)

    shipments.find_each do |shipment|
      next unless shipment.age_in_days.in?(Shipment::AGE_IN_DAYS_TO_FIRE_AGING_EVENTS)
      next if shipment.packages.any?

      Segments::SegmentService.from(shipment.order.storefront).aging_backorder_notification_created(shipment)
    end
  end
end
