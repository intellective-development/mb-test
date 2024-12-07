# frozen_string_literal: true

# Order::SendGiftOrderCreatedEventWorker
class Order::SendGiftOrderCreatedEventWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options \
    queue: 'sync_profile',
    retry: true,
    lock: :until_executing

  def perform_with_error_handling(order_id)
    order = Order.find(order_id)
    Segments::SegmentService.from(order.storefront).gift_order_created(order)
  end
end
