class Segment::SendProductsRefundedEventWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options \
    queue: 'sync_profile',
    retry: true,
    lock: :until_executing

  def perform_with_error_handling(order_id, order_item_id = nil)
    order = Order.find(order_id)
    order_item = OrderItem.find(order_item_id) if order_item_id

    Segments::SegmentService.from(order.storefront).products_refunded(order, order_item)
  end
end
