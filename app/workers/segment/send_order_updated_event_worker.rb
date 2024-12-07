class Segment::SendOrderUpdatedEventWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options \
    queue: 'sync_profile',
    retry: true,
    lock: :until_executing

  def perform_with_error_handling(order_id, update_type)
    order = Order.find(order_id)
    Segments::SegmentService.from(order.storefront).order_updated(order, update_type)
  end
end
