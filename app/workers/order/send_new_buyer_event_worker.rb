class Order::SendNewBuyerEventWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options \
    queue: 'sync_profile',
    retry: true,
    lock: :until_executing

  def perform_with_error_handling(order_id)
    order = Order.find(order_id)
    Segments::SegmentService.from(order.storefront).new_buyer_event(order)
  end
end
