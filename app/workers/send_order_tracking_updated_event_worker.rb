class SendOrderTrackingUpdatedEventWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options \
    queue: 'sync_profile',
    retry: true,
    lock: :until_executing

  def perform_with_error_handling(package_id, subtag, subtag_message)
    package = Package.find(package_id)
    order = package.shipment.order
    segment = Segments::SegmentService.from(order.storefront)

    if order.gift?
      segment.gift_order_tracking_updated(package, subtag, subtag_message)
    else
      segment.order_tracking_updated(package, subtag, subtag_message)
    end
  end
end
