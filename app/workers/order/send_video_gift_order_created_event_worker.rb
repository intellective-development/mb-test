class Order::SendVideoGiftOrderCreatedEventWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options \
    queue: 'sync_profile',
    retry: true,
    lock: :until_executing

  def perform_with_error_handling(order_id)
    order = Order.find(order_id)
    Segments::SegmentService.from(order.storefront).video_gift_order_created(order)
  end
end
