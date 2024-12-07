class SegmentOrderCancelledWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options \
    queue: 'sync_profile',
    retry: true,
    lock: :until_executing

  def perform_with_error_handling(order_id)
    return unless (order = Order.find_by(id: order_id))

    Segments::SegmentService.from(order.storefront).order_cancelled(order)
  end
end
